require 'sinatra/base'
require 'ey_services_fake/models'

module EyServicesFake
  class ReacharoundAwsm
    class Application < Sinatra::Base
      enable :raise_errors
      disable :dump_errors
      disable :show_exceptions

      post '/dashboard_notifications_url' do
        {}.to_json
      end

      get '/dashboard' do
        "Hello this is fake AWSM dashboard"
      end

    end

    def app
      Application
    end

    def reset!
      #no-op
    end

    def base_url
      "http://cloud.engineyard.com"
    end

    class Account < EyServicesFake::Model; end
    class AppDeployment < EyServicesFake::Model
      belongs_to :App, :app, :app_id
      belongs_to :Environment, :environment, :environment_id
    end
    class App < EyServicesFake::Model; end
    class Environment < EyServicesFake::Model; end
    class User < EyServicesFake::Model
      has_many :Account, :accounts, :owner_id
    end

    def service_provider_setup(auth_id, auth_key, service_provider_url, service_provider_rackapp)
      @connection = EY::ApiHMAC::AuthedConnection.new(auth_id, auth_key).tap{|c| c.backend = service_provider_rackapp}
    end
    def setup(auth_id, auth_key, tresfiestas_url, tresfiestas_rackapp)
      #ignored... we don't talk to tresfiestas, we talk to service_provider
    end

    def sso_user
      the_one_email = "the-one-user@example.com"
      User.first(:email => the_one_email) || User.create(:email => the_one_email, :external_service_id => Object.new.object_id)
    end

    def find_sso_account(sso_user)
      account = sso_user.accounts.first
      account && {
        :id => account.id,
        :name => account.name,
      }
    end
    def create_sso_account(sso_user)
      Account.create(:owner_id => sso_user.id, :name => 'some-account')
      find_sso_account(sso_user)
    end

    def find_app_deployment(sso_account_id)
      app_deployment = AppDeployment.first(:account_id => sso_account_id)
      app_deployment && {
        :id => app_deployment.id,
        :app => {
          :id => app_deployment.app.id,
          :name => app_deployment.app.name,
        },
        :environment => {
          :id => app_deployment.environment.id,
          :name => app_deployment.environment.name,
          :framework_env => app_deployment.environment.framework_env,
          :aws_region => app_deployment.environment.aws_region
        }
      }
    end
    def create_app_deployment(sso_account_id, app_name, env_name, framework_env)
      app = App.create(:name => app_name)
      env = Environment.create(:name => env_name, :framework_env => framework_env, :aws_region => 'us-east-1')
      AppDeployment.create(:account_id => sso_account_id, :app_id => app.id, :environment_id => env.id)
    end

    #Normal implmentations of AWSM would not be posting to service_accounts_url;
    #they would be posting to private API to say that they wish to create a service account
    #but this is reacharound AWSM, and so it plays the role of tresfiestas internals here
    # def enable_service(connection, sso_account, service_hash)
    def enable_service(service_id, sso_account_id)
      url_gen = EyServicesFake::URL_GEN
      service_account = ServiceAccount.create(:sso_account_id => sso_account_id, :active => false, :service_id => service_id, :dashboard_notifications_url => "#{base_url}/dashboard_notifications_url")
      service = Service.get(service_id)
      creation_attributes = {
        :id             => service_account.id,
        :name           => Account.get(sso_account_id).name,
        :url            => url_gen.partner_service_account(service, service_account),
        :messages_url   => url_gen.messages(service, service_account),
        :invoices_url   => url_gen.invoices(service, service_account),
      }
      @connection.post(service.service_accounts_url, creation_attributes) do |result, location|
        service_account.active = true
        if result["service_account"]
          service_account.provisioned_services_url = result["service_account"]['provisioned_services_url']
          service_account.configuration_url = result["service_account"]['configuration_url']
          service_account.url = result["service_account"]['url']
          service_account.configuration_required = result["service_account"]['configuration_required']
          service_account.users_url = result["service_account"]['users_url']
        end
        if result["message"] && result["message"]["message_type"]
          Message.create(
            :service_account_id => service_account.id,
            :message_type => result["message"]["message_type"],
            :subject => result["message"]["subject"],
            :body => result["message"]["body"])
        end
        service_account.save
      end
    end

    def disable_service(service_id, sso_account_id, service_account_id)
      service_account = ServiceAccount.get(service_account_id)
      @connection.delete(service_account.url)
    end

    def provision_service(sso_account_id, service_account_id, app_deployment_id)
      url_gen = EyServicesFake::URL_GEN
      provisioned_service = ProvisionedService.create(:app_deployment_id => app_deployment_id.to_i, :active => false, :service_account_id => service_account_id.to_i, :dashboard_notifications_url => "#{base_url}/dashboard_notifications_url")
      service_account_object = ServiceAccount.get(service_account_id)
      app_deployment = AppDeployment.get(app_deployment_id)
      app = app_deployment.app
      environment = app_deployment.environment
      provision_attribtues = {
        :url          => url_gen.partner_provisioned_service(service_account_object, provisioned_service),
        :messages_url => url_gen.messages(service_account_object.service, service_account_object, provisioned_service),
        :app          => {:id => app.id, :name => app.name},
        :environment  => {:id => environment.id, :name => environment.name, :framework_env => environment.framework_env, :aws_region => environment.aws_region},
      }
      @connection.post(service_account_object.provisioned_services_url, provision_attribtues) do |result, location|
        provisioned_service.active = true
        if result['provisioned_service']
          provisioned_service.vars = result['provisioned_service']["vars"]
          provisioned_service.configuration_url = result['provisioned_service']["configuration_url"]
          provisioned_service.configuration_required = result['provisioned_service']["configuration_required"]
          provisioned_service.url = result['provisioned_service']["url"]
          if result["message"] && result["message"]["message_type"]
            Message.create(
              :provisioned_service_id => provisioned_service.id,
              :message_type => result["message"]["message_type"],
              :subject => result["message"]["subject"],
              :body => result["message"]["body"])
          end
        end
        provisioned_service.save
      end
    end

    def deprovision_service(provisioned_service_id)
      provisioned_service = ProvisionedService.get(provisioned_service_id)
      @connection.delete(provisioned_service.url)
    end

    def service_account_sso_url(service_id, sso_user, sso_account_id)
      service_account = ServiceAccount.first(
        :sso_account_id => sso_account_id, :service_id => service_id)
      partner = service_account.service.partner
      configuration_url = service_account.configuration_url
      params = {
        'timestamp' => Time.now.iso8601,
        'ey_user_id' => sso_user.external_service_id,
        'ey_user_name' => "Person Name",
        'ey_return_to_url' => "https://cloud.engineyard.com/dashboard",
        'access_level' => 'owner',
      }
      if service_account.users_url
        params['ey_user_email'] = sso_user.email
      end
      require 'cgi'
      EY::ApiHMAC::SSO.sign(configuration_url,
                            params,
                            partner.auth_id,
                            partner.auth_key)
    end

    def provisioned_service_sso_url(service_account_id, app_deployment_id, sso_user, sso_account_id)
      service_account = ServiceAccount.get(service_account_id)
      partner = service_account.service.partner
      provisioned_service = ProvisionedService.first(:app_deployment_id => app_deployment_id)
      configuration_url = provisioned_service.configuration_url
      params = {
        'timestamp' => Time.now.iso8601,
        'ey_user_id' => sso_user.external_service_id,
        'ey_user_name' => "Person Name",
        'ey_return_to_url' => "https://cloud.engineyard.com/dashboard",
        'access_level' => 'owner',
      }
      if service_account.users_url
        params['ey_user_email'] = sso_user.email
      end
      require 'cgi'
      EY::ApiHMAC::SSO.sign(configuration_url,
                            params,
                            partner.auth_id,
                            partner.auth_key)
    end

  end
end
