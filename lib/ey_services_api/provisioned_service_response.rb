module EY
  module ServicesAPI
    class ProvisionedServiceResponse < Struct.new(:configuration_required, :configuration_url, :message, :url)
      def to_hash
        {
          :message => self.message.to_hash
        }
      end
    end
  end
end