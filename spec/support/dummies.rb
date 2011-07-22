module EY
  module ServicesAPI
    Service.class_eval do

      def self.dummy_attributes
        {
          :name => "Test Service",
          :description => "my compliments to the devops",
          :service_accounts_url =>     "http://example.com/service_accounts",
          :home_url =>                 "http://example.com/",
          :terms_and_conditions_url => "http://example.com/terms",
          :vars => [
            "COMPLIMENTS_API_KEY",
            "CIA_BACKDOOR_PASSWORD"
          ]
        }
      end

    end
  end
end