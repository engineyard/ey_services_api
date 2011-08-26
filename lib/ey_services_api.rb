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

    def self.connection
      @connection or raise "Not setup!"
    end

    def self.enable_mock!(provider = nil)
      unless @mock_backend
        unless provider
          require "ey_services_api/test/tresfiestas_fake"
          provider = TresfiestasFake
        end
        @mock_backend = provider.setup!
      end
      @mock_backend.reset!
      @mock_backend.initialize_api_connection
    end

    def self.mock_backend
      @mock_backend
    end

  end
end
