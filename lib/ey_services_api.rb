require "ey_services_api/version"
require "ey_services_api/api_struct"
require "ey_services_api/connection"
require "ey_services_api/service"
require "ey_services_api/message"
require "ey_services_api/invoice"
require "ey_services_api/service_account_creation"
require "ey_services_api/service_account_response"
require "ey_services_api/provisioned_service_creation"
require "ey_services_api/provisioned_service_response"

module EY
  module ServicesAPI

    def self.setup!(opts)
      @connection = Connection.new(opts[:auth_id], opts[:auth_key])
    end

    def self.setup?
      @connection
    end

    def self.connection
      @connection or raise "Not setup!"
    end

    def self.enable_mock!(service_provider, tresfiestas = nil, awsm = nil)
      unless @mock_backend
        #TODO: rescue load error and log the need to include ey_services_fake gem
        require "ey_services_fake/mock_backend"
        @mock_backend = EyServicesFake::MockBackend.setup!(
          :awsm => awsm,
          :tresfiestas => tresfiestas,
          :service_provider => service_provider)
      end
      @mock_backend.reset!
    end

    def self.mock_backend
      @mock_backend
    end

  end
end
