module EY
  module ServicesAPI
    class Integration

      def self.register_service(registration_url, service_url)
        create_service(service_registration_params(service_url), registration_url)
      end

      def self.server
        Server
      end

      def self.mapper=(mapper)
        @mapper = mapper
      end

      def self.mapper
        @mapper
      end

    private

      def self.service_registration_params(base_url)
        {
          :name                     => fetch_from_description(:name),
          :label                    =>  fetch_from_description(:label),
          :service_accounts_url     => "#{base_url + mapper.api_root}/service_accounts",
          :home_url                 => fetch_from_description(:home_url),
          :terms_and_conditions_url => fetch_from_description(:terms_and_conditions_url),
        }
      end

      def self.fetch_from_description(thing)
        mapper.description[thing] or raise "Expected 'description' to define a #{thing} for your service"
      end

      def self.create_service(registration_params, service_registration_url)
        remote_service = connection.register_service(service_registration_url, registration_params)
        mapper.save_service_url(remote_service.url)
        remote_service
      end

      def self.connection
        unless EY::ServicesAPI.setup?
          EY::ServicesAPI.setup!(mapper.api_creds)
        end
        EY::ServicesAPI.connection
      end

      def self.test_setup(auth_id, auth_key, tresfiestas_url, tresfiestas_rackapp)
        mapper.save_api_creds(auth_id, auth_key)
        connection.backend = tresfiestas_rackapp
      end

    end
  end
end