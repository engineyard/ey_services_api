module EY
  module ServicesAPI
    class Invoice < APIStruct.new(:total_amount_cents, :line_item_description, :unique_id)
      attr_accessor :connection
      attr_accessor :url
      attr_accessor :status

      def destroy
        connection.destroy_invoice(self.url)
      end

    end
  end
end