module EY
  module ServicesAPI
    class ProvisionedServiceResponse < APIStruct.new(:configuration_required, :configuration_url, :message, :vars, :url)
      def to_hash
        {
          :provisioned_service      => {
            :url                    => self.url,
            :configuration_required => self.configuration_required,
            :configuration_url      => self.configuration_url,
            :vars                   => self.vars,
          },
          :message                  => self.message && self.message.to_hash,
        }
      end
    end
  end
end