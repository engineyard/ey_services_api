require 'rack/client'
require 'json'
require 'ey_api_hmac'

module EY
  module ServicesAPI
    class Connection < EY::ApiHMAC::AuthedConnection

      def default_user_agent
        "EY-ServicesAPI/#{VERSION}"
      end

      def list_services(url)
        response = get(url) do |json_body, response_location|
          json_body.map do |json_item|
            service = Service.new(json_item["service"])
            service.connection = self
            service.url = json_item["service"]["url"]
            service
          end
        end
      end

      def register_service(registration_url, params)
        post(registration_url, :service => params) do |json_body, response_location|
          service = Service.new(params)
          service.connection = self
          service.url = response_location
          service
        end
      end

      def get_service(url)
        get(url) do |json_body, response_location|
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

      def update_service_account(url, params)
        put(url, :service_account => params)
      end

      def update_provisioned_service(url, params)
        put(url, :provisioned_service => params)
      end

      def send_message(url, message)
        post(url, :message => message.to_hash)
      end

      def send_invoice(invoices_url, invoice)
        post(invoices_url, :invoice => invoice.to_hash)
      end

      def list_invoices(invoices_url)
        get(invoices_url) do |json_body, response_location|
          json_body.map do |json_item|
            invoice = Invoice.new(json_item["invoice"])
            invoice.connection = self
            invoice.url = json_item["invoice"]["url"]
            invoice.status = json_item["invoice"]["status"]
            invoice
          end
        end
      end

      def destroy_invoice(url)
        delete(url)
      end

    end
  end
end