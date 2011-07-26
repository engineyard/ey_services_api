module EY
  module ServicesAPI
    class ServiceAccount < APIStruct.new(:name, :url, :messages_url, :invoices_url)

      def self.create_from_request(request)
        json = JSON.parse(request)
        json[:vars] = {}
        new(json)
      end

      def creation_response_hash
        response_presenter = ServiceAccountResponse.new
        yield response_presenter
        response_presenter.to_hash
      end

    end
  end
end