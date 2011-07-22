module EY
  module ServicesAPI
    class Service < Struct.new(:name, :description, :home_url, :service_accounts_url, :terms_and_conditions_url, :vars)
      def initialize(atts = {})
        super(*atts.values_at(*Service.members.map(&:to_sym)))
      end
    end
  end
end