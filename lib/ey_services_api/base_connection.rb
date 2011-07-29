require 'rack/client'
require 'json'

module EY
  module ServicesAPI
    class BaseConnection
      attr_reader :api_secret

      def initialize(api_secret, user_agent = nil)
        @api_secret = api_secret
        @standard_headers = {
            'CONTENT_TYPE' => 'application/json',
            'Accept'=> 'application/json', 
            'USER_AGENT' => user_agent || default_user_agent
        }
      end

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

      protected

      def request(method, url, body = nil, &block)
        if body
          response = client.send(method, url, @standard_headers, body.to_json)
        else
          response = client.send(method, url, @standard_headers)
        end
        handle_response(url, response, &block)
      end

      def post(url, body, &block)
        request(:post, url, body, &block)
      end
      
      def put(url, body, &block)
        request(:put, url, body, &block)
      end
      
      def delete(url, &block)
        request(:delete, url, &block)
      end

      def get(url, &block)
        request(:get, url, &block)
      end

      def handle_response(url, response)
        case response.status
        when 200, 201
          json_body = JSON.parse(response.body)
          yield json_body, response["Location"] if block_given?
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