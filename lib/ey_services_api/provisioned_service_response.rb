module EY
  module ServicesAPI
    class ProvisionedServiceResponse < APIStruct.new(:configuration_required, :configuration_url, :message, :vars, :url, :api_version)

      def to_hash
        if api_version == 2
          {
            :resource     => {
            :url                    => self.url,
            :configuration_url      => self.configuration_url,
            :vars                   => self.vars,
            }
          }
        else
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
end