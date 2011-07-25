module EY
  module ServicesAPI
    class Service < Struct.new(:name, :description, :home_url, :service_accounts_url, :terms_and_conditions_url, :vars)
      attr_accessor :connection
      attr_accessor :url

      def initialize(atts = {})
        #converting all keys of atts to Symbols
        atts = Hash[atts.map {|k,v| [k.to_sym, v]}]

        super(*atts.values_at(*self.members.map(&:to_sym)))
      end

      def to_hash
        Hash[members.zip(entries)]
      end

      def update(atts)
        new_atts = self.to_hash.merge(atts)
        connection.update_service(self.url, new_atts)
        update_from_hash(new_atts)
      end

      def destroy
        connection.destroy_service(self.url)
      end

      protected

      def update_from_hash(atts)
        atts.each do |k, v|
          self.send("#{k}=", v)
        end
      end

    end
  end
end