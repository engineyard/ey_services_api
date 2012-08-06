module EY
  module ServicesAPI
    class ServiceAccountCreation < APIStruct.new(:id, :name, :url, :messages_url, :invoices_url)

      def self.from_request(request)
        json = JSON.parse(request)
        new(json)
      end

    end
  end
end