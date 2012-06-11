require 'sinatra/base'

module EY
  module ServicesAPI
    class Integration
      class Server < Sinatra::Base

        enable :raise_errors
        disable :dump_errors
        disable :show_exceptions

        use EY::ApiHMAC::ApiAuth::LookupServer do |env, auth_id|
          Integration.mapper.api_creds && (Integration.mapper.api_creds[:auth_id] == auth_id) && Integration.mapper.api_creds[:auth_key]
        end

        post "/service_accounts" do
          request_body = request.body.read
          service_account = EY::ServicesAPI::ServiceAccountCreation.from_request(request_body)
          created = mapper.service_account_create(service_account)
          response_params = {
            :configuration_required   => false,
            :configuration_url        => nil,
            :provisioned_services_url => "#{api_base_url}/customers/#{created[:id]}/pairs",
            :url                      => "#{api_base_url}/customers/#{created[:id]}"
          }
          response = EY::ServicesAPI::ServiceAccountResponse.new(response_params)
          content_type :json
          headers 'Location' => response.url
          response.to_hash.to_json
        end

        private

        def mapper
          Integration.mapper
        end

        def api_base_url
          true_base_url + mapper.api_root
        end

        def true_base_url
          uri = URI.parse(request.url)
          uri.to_s.gsub(uri.request_uri, '')
        end

      end
    end
  end
end