require 'sinatra/base'

module EyServicesFake
  class MockingBirdService

    def self.implement_the_app(app)
      app.class_eval do
        enable :raise_errors
        disable :dump_errors
        disable :show_exceptions

        class << self
          attr_accessor :parent
        end
        def parent
          self.class.parent
        end

        delete '/api/1/some_provisioned_service' do
          content_type :json
          if parent.service_deprovisioning_handler
            instance_eval(&parent.service_deprovisioning_handler)
          else
            {}.to_json
          end
        end

        delete '/api/1/account/:account_id' do |account_id|
          content_type :json
          if parent.service_account_cancel_handler
            instance_eval(&parent.service_account_cancel_handler)
          else
            {}.to_json
          end
        end

        post '/api/1/service_accounts_callback' do
          content_type :json
          if parent.service_account_creation_handler
            instance_eval(&parent.service_account_creation_handler)
          else
            service_account = EY::ServicesAPI::ServiceAccountCreation.from_request(request.body.read)
            response_params = parent.service_account_creation_params(123)
            EY::ServicesAPI::ServiceAccountResponse.new(response_params).to_hash.to_json
          end
        end

        post '/api/1/account/:account_id/provisioned_services_callback' do |account_id|
          content_type :json
          if parent.service_provisioning_handler
            instance_eval(&parent.service_provisioning_handler)
          else
            provisioned_service = EY::ServicesAPI::ProvisionedServiceCreation.from_request(request.body.read)
            standard_response_params = parent.service_provisioned_params
            EY::ServicesAPI::ProvisionedServiceResponse.new(parent.service_provisioned_params).to_hash.to_json
          end
        end

        post '/api/2/resources_callback' do
          content_type :json
          if parent.service_provisioning_handler
            instance_eval(&parent.service_provisioning_handler)
          else
            EY::ServicesAPI::ProvisionedServiceResponse.new(parent.v2_service_provisioning_params).to_hash.to_json
          end
        end

        delete '/api/2/resources_callback' do
          content_type :json
          if parent.service_deprovisioning_handler
            instance_eval(&parent.service_deprovisioning_handler)
          else
            {}.to_json
          end
        end

        get '/sso/account/:account_id' do |account_id|
          parent.account_sso_hook(params)
          "SSO Hello Service Account"
        end

        get '/sso/some_provisioned_service' do
          "SSO Hello Provisioned Service"
        end
      end
    end
    class << self
      attr_accessor :service_account_creation_handler
      attr_accessor :service_provisioning_handler
      attr_accessor :service_deprovisioning_handler
      attr_accessor :service_account_cancel_handler
      attr_accessor :v2_service_provisioning_handler
      attr_accessor :v2_service_deprovisioning_handler
    end

    def reset!
      self.class.service_account_creation_handler = nil
      self.class.service_provisioning_handler = nil
      self.class.service_deprovisioning_handler = nil
      self.class.service_account_cancel_handler = nil
      self.class.v2_service_provisioning_handler = nil
      self.class.v2_service_deprovisioning_handler = nil
    end

    def make_app
      app = Class.new(Sinatra::Base)
      self.class.implement_the_app(app)
      app.parent = self.class
      app
    end

    def app
      @app ||= make_app
    end

    def setup(auth_id, auth_key, base_url = nil, backend = nil)
      require 'ey_services_api'
      connection = EY::ServicesAPI.setup!(:auth_id => auth_id, :auth_key => auth_key)
      if backend
        connection.backend = backend
      end
    end

    def base_url
      self.class.base_url
    end
    def self.base_url
      "http://mock.service/"
    end

    def registration_params
      self.class.registration_params
    end
    def self.registration_params(api_version = 1)
      params = {
        :name => "Mocking Bird",
        :label => "mocking_bird",
        :description => "a mock service",
        :home_url =>                 "#{base_url}",
        :terms_and_conditions_url => "#{base_url}terms",
        :vars => ["some_var", "other_var"]
      }
      params.merge!(:service_accounts_url => "#{base_url}api/1/service_accounts_callback")
      params.merge!(:resources_url => "#{base_url}api/2/resources_callback", :level => "environment") if api_version == 2
      params
    end

    def service_account_creation_params(account_id)
      self.class.service_account_creation_params(account_id)
    end
    def self.service_account_creation_params(account_id)
      {
        :provisioned_services_url => "#{base_url}api/1/account/#{account_id}/provisioned_services_callback",
        :url => "#{base_url}api/1/account/#{account_id}",
        :configuration_url => "#{base_url}sso/account/#{account_id}",
        :configuration_required => false,
        :message => EY::ServicesAPI::Message.new(:message_type => "status", :subject => "some messages")
      }
    end

    def service_provisioned_params
      self.class.service_provisioned_params
    end
    def self.service_provisioned_params
      {
        :vars => {"some_var" => "value", "other_var" => "blah"},
        :configuration_url => "#{base_url}sso/some_provisioned_service",
        :configuration_required => false,
        :url => "#{base_url}api/1/some_provisioned_service",
        :message => EY::ServicesAPI::Message.new(:message_type => "status", :subject => "some provisioned service messages")
      }
    end

    def self.account_sso_hook(params)
      #no-op
    end

    def register_service(registration_url, api_version = 1)
      EY::ServicesAPI.connection.register_service(registration_url, self.class.registration_params(api_version))
    end

    def send_message(message_url, message_type, message_subject, message_body)
      message = EY::ServicesAPI::Message.new(:message_type => message_type, :subject => message_subject, :body => message_body)
      EY::ServicesAPI.connection.send_message(message_url, message)
    end

    def send_invoice(invoices_url, total_amount_cent, line_item_description)
      invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => total_amount_cent,
                                             :line_item_description => line_item_description)
      EY::ServicesAPI.connection.send_invoice(invoices_url, invoice)
    end

    def v2_service_provisioning_params
      self.class.v2_service_provisioning_params
    end

    def self.v2_service_provisioning_params
      account_id = 25
      {
        :vars => {"some_var" => "value", "other_var" => "blah"},
        :url => "#{base_url}api/2/account/#{account_id}",
        :configuration_url => "#{base_url}sso/account/#{account_id}",
        :api_version => 2
      }
    end

  end
end
