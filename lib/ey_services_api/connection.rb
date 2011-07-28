require 'rack/client'
require 'json'

module EY
  module ServicesAPI
    class Connection < Struct.new(:api_secret)

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

      def register_service(registration_url, params)
        post(registration_url, :service => params) do |json_body, response_location|
          service = Service.new(params)
          service.connection = self
          service.url = response_location
          service
        end

        # response = self.client.post(registration_url, STANDARD_HEADERS, {:service => params}.to_json)
        # 
        # handle_response(registration_url, response) do
        #   service = Service.new(params)
        #   service.connection = self
        #   service.url = response["Location"]
        #   service
        # end
      end

      def get_service(url)
        response = get(url) do |json_body|
          service = Service.new(json_body["service"])
          service.connection = self
          service.url = url
          service
        end
      end

      def update_service(url, params)
        put(url, :service => params)
      end

      def destroy_service(url)
        delete(url)
      end

      #Jacob: will refactor if reach 200 lines!

      def send_message(url, message)
        post(url, :message => message.to_hash)
      end

      def send_invoice(invoices_url, invoice)
        # #TODO: charge per compliment generator?
        # invoice_params = {
        #   :invoice => {
        #     :total_amount_cents => total_price,
        #     :line_item_description => "For service from #{last_billed_at} to #{billing_at}, "+
        #                               "includes #{compliment_generators.size} compliment generators."
        #   }
        # }
        post(invoices_url, :invoice => invoice.to_hash)
        # response = RestClient.post(
        #                     invoices_url,
        #                     {:invoice => invoice.to_hash}.to_json,
        #                     :content_type => :json,
        #                     :accept => :json, :user_agent => "Lisonja")
        # response_data = JSON.parse(response.body)
        #TODO: do something with the response?
        #TODO: test that you can't bill a different customer
        #WHEN testing: handling what happens when you attempt to bill $0 or a negative amount?
      end

      protected

      def request(method, url, body = nil, &block)
        response = client.send(method, url, STANDARD_HEADERS, body.to_json)
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