require 'sinatra/base'

module EyServicesFake
  class MockingBirdService
    class Application < Sinatra::Base
      enable :raise_errors
      disable :dump_errors
      disable :show_exceptions

      delete '/api/1/some_provisioned_service' do
        {}.to_json
      end

      delete '/api/1/some_service_account' do
        {}.to_json
      end

      post '/api/1/service_accounts_callback' do
        service_account = EY::ServicesAPI::ServiceAccountCreation.from_request(request.body.read)
        standard_response_params = MockingBirdService.service_account_creation_params
        EY::ServicesAPI::ServiceAccountResponse.new(
          :provisioned_services_url => standard_response_params[:provisioned_services_url],
          :url                      => standard_response_params[:url],
          :configuration_url        => standard_response_params[:configuration_url],
          :configuration_required   => standard_response_params[:configuration_required],
          :message                  => EY::ServicesAPI::Message.new(:message_type => "status", :subject => "some messages")
        ).to_hash.to_json
      end

      post '/api/1/provisioned_services_callback' do
        provisioned_service = EY::ServicesAPI::ProvisionedServiceCreation.from_request(request.body.read)
        standard_response_params = MockingBirdService.service_provisioned_params
        EY::ServicesAPI::ProvisionedServiceResponse.new(
          :url                    => standard_response_params[:url],
          :vars                   => standard_response_params[:vars],
          :configuration_required => false,
          :configuration_url      => standard_response_params[:configuration_url],
          :message                => EY::ServicesAPI::Message.new(:message_type => "status", :subject => "some provisioned service messages")
        ).to_hash.to_json
      end

      get '/sso/some_service_account' do
        "SSO Hello Service Account"
      end

      get '/sso/some_provisioned_service' do
        "SSO Hello Provisioned Service"
      end
    end

    def reset!
      #no-op
    end

    def app
      Application
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
    def self.registration_params
      {
        :name => "Mocking Bird",
        :label => "mocking_bird",
        :description => "a mock service",
        :service_accounts_url =>     "#{base_url}api/1/service_accounts_callback",
        :home_url =>                 "#{base_url}",
        :terms_and_conditions_url => "#{base_url}terms",
        :vars => ["some_var", "other_var"]
      }
    end

    def service_account_creation_params
      self.class.service_account_creation_params
    end
    def self.service_account_creation_params
      {
        :provisioned_services_url => "#{base_url}api/1/provisioned_services_callback",
        :url => "#{base_url}api/1/some_service_account",
        :configuration_url => "#{base_url}sso/some_service_account",
        :configuration_required => false
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
      }
    end

    def register_service(registration_url)
      EY::ServicesAPI.connection.register_service(registration_url, MockingBirdService.registration_params)
    end

    def send_message(message_url, message_type, message_subject, message_body)
      message = EY::ServicesAPI::Message.new(:message_type => message_type, :subject => message_subject, :body => message_body)
      EY::ServicesAPI.connection.send_message(message_url, message)
    end

  end
end
