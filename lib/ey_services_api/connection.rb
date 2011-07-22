require 'rack/client'
require 'json'

module EY
  module ServicesAPI
    class Connection < Struct.new(:registration_url, :api_secret)

      attr_accessor :backend

      def register_service(params)
        service = Service.new(params)

        service_creation_params = {
          :service => params
        }

        back = self.backend
        client = Rack::Client.new do
          run back
        end

        response = client.post(
                            self.registration_url,
                            {'CONTENT_TYPE' => 'application/json',
                             'Accept'=> 'application/json', 
                             'USER_AGENT' => "Lisonja"},
                             service_creation_params.to_json)
                             
        puts "Response: " + response.inspect
        puts "Response: #{response.body}"
        puts "Response: #{response.status}"
        
        response_data = JSON.parse(response.body)
        
        puts response_data.inspect
        
        service
      end
    end
  end
end