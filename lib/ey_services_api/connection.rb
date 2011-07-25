require 'rack/client'
require 'json'

module EY
  module ServicesAPI
    puts "loading the Connection class.."
    class Connection < Struct.new(:registration_url, :api_secret)

      class NotFound < StandardError
        def initialize(url)
          super("#{url} not found")
        end
      end

      class ValidationError < StandardError
        attr_reader :error_messages

        def initialize(response)
          json_response = nil
          begin
            json_response = JSON.parse(response.body)
          rescue => e
          end
          if json_response
            @error_messages = json_response["error_messages"]
            super("error: #{@error_messages.join("\n")}")
          else
            @error_messages = []
            super("error: #{response.body}")
          end
        end
      end

      class UnknownError < StandardError
        def initialize(response)
          super("unknown error(#{response.status}): #{response.body}")
        end
      end

      attr_writer :backend
      def backend
        @backend ||= Rack::Client::Handler::NetHTTP
      end

      def client
        bak = self.backend
        @client ||= Rack::Client.new do
          run bak
        end
      end

      #TODO: stanard USER_AGENT should be EY::ServicesAPI/v0.0.1  but editable to be Lisonja for the spikes
      STANDARD_HEADERS = {
          'CONTENT_TYPE' => 'application/json',
          'Accept'=> 'application/json', 
          'USER_AGENT' => "Lisonja"}

      def register_service(params)
        post_to_url = self.registration_url
        response = self.client.post(post_to_url, STANDARD_HEADERS, {:service => params}.to_json)

        handle_response(post_to_url, response) do
          service = Service.new(params)
          service.connection = self
          service.url = response["Location"]
          service
        end
      end

      def get_service(url)
        response = self.client.get(url, STANDARD_HEADERS)
        service = nil
        handle_response(url, response) do |json_body|
          service = Service.new(json_body["service"])
          service.connection = self
          service.url = url
          service
        end
      end

      def update_service(url, params)
        response = self.client.put(url, STANDARD_HEADERS, {:service => params}.to_json)
        handle_response(url, response)
      end

      def destroy_service(url)
        response = self.client.delete(url, STANDARD_HEADERS)
        handle_response(url, response)
      end

      protected
      def handle_response(url, response)
        case response.status
        when 200, 201
          json_body = JSON.parse(response.body)
          yield json_body if block_given?
        when 404
          raise NotFound.new(url)
        when 400
          raise ValidationError.new(response)
        else
          raise UnknownError.new(response)
        end
      end
    end
  end
end