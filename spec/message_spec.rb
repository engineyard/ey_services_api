require 'spec_helper'
require 'sinatra'

#TODO: support a generic message class too?
describe EY::ServicesAPI::StatusMessage do
  include_context 'tresfiestas setup'

  describe "#send_message" do
    describe "with a service account" do
      before do
        @service_account = @tresfiestas.create_service_account
        @messages_url = @service_account[:messages_url]
        api_token = @service_account[:service][:partner][:api_token]
        @connection = EY::ServicesAPI::Connection.new(api_token)
      end

      it "POSTs to the message callback URL to send a message" do

        message = EY::ServicesAPI::StatusMessage.new(:subject => "Subjecty", :body => "Whee")
        @connection.send_message(@messages_url, message)

        latest = @tresfiestas.latest_status_message
        latest.should_not be_blank
        latest[:service_account_id].should == @service_account[:id]

        latest[:subject].should === "Subjecty"
        latest[:body].should === "Whee"
      end

      it "returns an error when the message is not valid" do
        lambda{
          @connection.send_message(@messages_url, EY::ServicesAPI::StatusMessage.new(:subject => "", :body => ""))
        }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Subject can't be blank/)
      end

    end

    describe "with a provisioned service" do
      before do
        @provisioned_service = @tresfiestas.create_provisioned_service
        @messages_url = @provisioned_service[:messages_url]
        api_token = @provisioned_service[:service_account][:service][:partner][:api_token]
        @connection = EY::ServicesAPI::Connection.new(api_token)
      end

      it "POSTs to the message callback URL to send a message" do
        message = EY::ServicesAPI::StatusMessage.new(:subject => "Subjectish", :body => "Bodily")
        @connection.send_message(@messages_url, message)

        latest = @tresfiestas.latest_status_message
        latest.should_not be_blank
        latest[:provisioned_service_id].should == @provisioned_service[:id]

        latest[:subject].should === "Subjectish"
        latest[:body].should === "Bodily"
      end

      it "returns an error when the message is not valid" do
        lambda{
          @connection.send_message(@messages_url, EY::ServicesAPI::StatusMessage.new(:subject => "", :body => ""))
        }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Subject can't be blank/)
      end

    end

  end
end