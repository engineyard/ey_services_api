require 'ey_services_fake/url_generator'
require 'ey_services_fake/models'
require 'ey_services_fake/tresfiestas_fake_rack_app'

module EyServicesFake
  BASE_URL = "http://services.engineyard.com"
  URL_GEN = EyServicesFake::UrlGenerator.new(BASE_URL)

  class TresfiestasFake

    def reset!
      Model.nuke_all
    end

    def base_url
      BASE_URL
    end

    def app
      TresfiestasFakeRackApp
    end

    def find_awsm
      awsm_object = Awsm.first
      awsm_object && {
        :id => awsm_object.id,
        :auth_id => awsm_object.auth_id,
        :auth_key => awsm_object.auth_key,
      }
    end

    def create_awsm(awsm_base_url, awsm_app)
      Awsm.create(:auth_id => "789eef", :auth_key => "009abb")
      app.awsm_connection = EY::ApiHMAC::AuthedConnection.new("789eef", "009abb")
      app.awsm_connection.backend = awsm_app
      find_awsm
    end

    def find_partner(sso_user)
      partner_object = Partner.first
      partner_object && {
        :id => partner_object.id,
        :name => partner_object.name,
        :auth_id => partner_object.auth_id,
        :auth_key => partner_object.auth_key,
        :registration_url => URL_GEN.service_registration(partner_object),
      }
    end

    def create_partner(sso_user, partner_base_url, partner_app)
      Partner.create(:auth_id => "123edf", :auth_key => "abc456", :name => "Some-Partner")
      app.partner_connection = EY::ApiHMAC::AuthedConnection.new("123edf", "abc456")
      app.partner_connection.backend = partner_app
      find_partner(sso_user)
    end

    def find_service(partner_id)
      partner_object = Partner.get!(partner_id)
      service_object = partner_object.services.first
      service_object && {
        :id => service_object.id,
        :name => service_object.name,
        :description => service_object.description,
        :home_url => service_object.home_url,
        :label => service_object.label,
        :revenue_share => service_object.revenue_share,
        :service_accounts_url => service_object.service_accounts_url,
      }
    end

    def service_available_for_account?(service_id, sso_account_id)
      Service.get(service_id).service_enablements.first(:sso_account_id => sso_account_id.to_s)
    end

    def make_service_available_for_account(service_id, sso_account_id, reason = "test")
      ServiceEnablement.create(:service_id => service_id.to_i, :sso_account_id => sso_account_id.to_s, :reason => reason)
    end

    def find_service_account(service_id, sso_account_id)
      service_object = Service.get(service_id)
      service_account_object = service_object.service_accounts.first(:sso_account_id => sso_account_id.to_s)
      service_account_object && {
        :id             => service_account_object.id,
        :url            => URL_GEN.partner_service_account(service_object, service_account_object),
        :messages_url   => URL_GEN.messages(service_object, service_account_object),
        :invoices_url   => URL_GEN.invoices(service_object, service_account_object),
        :pushed_service_account => {
          :provisioned_services_url => service_account_object.provisioned_services_url,
          :configuration_url => service_account_object.configuration_url,
          :url => service_account_object.url,
          :users_url => service_account_object.users_url,
          :configuration_required => service_account_object.configuration_required,
        }
      }
    end

    def find_provisioned_service(service_account_id, app_deployment_id)
      service_account = ServiceAccount.get(service_account_id)
      provisioned_service = service_account.provisioned_services.first(:app_deployment_id => app_deployment_id)
      provisioned_service && {
        :id => provisioned_service.id,
        :url => URL_GEN.partner_provisioned_service(service_account, provisioned_service),
        :messages_url => URL_GEN.messages(service_account.service, service_account, provisioned_service),
        :pushed_provisioned_service => {
          :vars => provisioned_service.vars,
          :configuration_url => provisioned_service.configuration_url,
          :configuration_required => provisioned_service.configuration_required,
          :url => provisioned_service.url
        }
      }
    end

    def latest_invoice
      invoice = Invoice.last
      {
        :total_amount_cents  => invoice.total_amount_cents,
        :line_item_description => invoice.line_item_description,
        :service_account_id => invoice.service_account_id,
      }
    end

    def latest_status_message
      if message = Message.last(:message_type => "status")
        to_return = {
          :id => message.id,
          :subject => message.subject,
          :body => message.body
        }
        if message.respond_to?(:service_account) && message.service_account
          to_return[:service_account_id] = message.service_account.id
        end
        if message.respond_to?(:provisioned_service) && message.provisioned_service
          to_return[:provisioned_service_id] = message.provisioned_service.id
        end
        to_return
      end
    end

    def trigger_mock_user_update(sso_user, new_email)
      sso_user.accounts.each do |account|
        ServiceAccount.all(:sso_account_id => account.id).each do |service_account|
          if service_account.users_url
            users = app.partner_connection.get(service_account.users_url){|json,_| json }
            users.each do |user|
              unless user["user"]["ey_user_email"] == new_email
                app.partner_connection.put(user["url"], :user => {:ey_user_email => new_email})
              end
            end
          end
        end
      end
    end

    def trigger_mock_user_delete(sso_user)
      sso_user.accounts.each do |account|
        ServiceAccount.all(:sso_account_id => account.id).each do |service_account|
          if service_account.users_url
            users = app.partner_connection.get(service_account.users_url){|json,_| json }
            users.each do |user|
              app.partner_connection.delete(user["url"])
            end
          end
        end
      end
    end

  end
end
