#because there may be multiple 'spec_helper' in load path when running from external test helper
require File.expand_path('../spec_helper.rb', __FILE__)
require 'sinatra'

#TODO: support a generic message class too?
describe EY::ServicesAPI::Message do
  describe "#send_message" do
    describe "with a service account" do
      before do
        @service_account = @tresfiestas.service_account
        @messages_url = @service_account[:messages_url]
        @connection = EY::ServicesAPI.connection
      end

      it "POSTs to the message callback URL to send a message" do
        message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => "Subjecty", :body => "Whee")
        @connection.send_message(@messages_url, message)

        latest = @tresfiestas.latest_status_message
        latest.should_not be_empty
      end

      it "returns an error when the message is not valid" do
        lambda{
          @connection.send_message(@messages_url, EY::ServicesAPI::Message.new(:subject => "", :body => ""))
        }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Subject can't be blank/)
      end

      it "returns an error when the message_type is not valid" do
        lambda{
          @connection.send_message(@messages_url, EY::ServicesAPI::Message.new(:message_type => "urgent_reminder", :subject => "valid"))
        }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Message type must be one of: status, notification or alert/)
      end

    end

    describe "with a provisioned service" do
      before do
        @provisioned_service = @tresfiestas.provisioned_service
        @messages_url = @provisioned_service[:messages_url]
        @connection = EY::ServicesAPI.connection
      end

      it "POSTs to the message callback URL to send a message" do
        message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => "Subjectish", :body => "Bodily")
        @connection.send_message(@messages_url, message)

        latest = @tresfiestas.latest_status_message
        latest.should_not be_empty
        latest[:provisioned_service_id].should == @provisioned_service[:id]

        latest[:subject].should === "Subjectish"
        latest[:body].should === "Bodily"
      end

      it "returns an error when the message is not valid" do
        lambda{
          @connection.send_message(@messages_url, EY::ServicesAPI::Message.new(:message_type => "status", :subject => "", :body => ""))
        }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Subject can't be blank/)
      end

      it "returns an error when the message_type is not valid" do
        lambda{
          @connection.send_message(@messages_url, EY::ServicesAPI::Message.new(:message_type => "urgent_reminder", :subject => "valid"))
        }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Message type must be one of: status, notification or alert/)
      end

    end

  end
end