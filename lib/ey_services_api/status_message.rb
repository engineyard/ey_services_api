module EY
  module ServicesAPI
    class StatusMessage < APIStruct.new( :subject, :body )

      def to_hash
        super.merge(:message_type => "status")
      end

    end
  end
end