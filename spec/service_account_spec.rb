require 'spec_helper'
require 'sinatra'

describe EY::ServicesAPI::ServiceAccount do
  include_context 'tresfiestas setup'

  describe "with a service account" do
    before do
      @service_account_hash = @tresfiestas.create_service_account
      @creation_request = @tresfiestas.service_account_creation_request(@service_account_hash)
      @service_account = EY::ServicesAPI::ServiceAccount.create_from_request(@creation_request.to_json)
    end

    it "can handle a service account creation request" do
      @service_account.url.should eq @creation_request[:url]
      @service_account.messages_url.should eq @creation_request[:messages_url]
      @service_account.invoices_url.should eq @creation_request[:invoices_url]
      @service_account.name.should eq @creation_request[:name]
    end

    it "can produce a response body hash for service account creation requests" do
      response_hash = @service_account.creation_response_hash do |presenter|
        presenter.provisioned_services_url = "some provision url"
        presenter.url = "some resource url"
        presenter.configuration_required = true
        presenter.configuration_url = "some config url" #doesn't even have to be valid here!
        presenter.message = EY::ServicesAPI::StatusMessage.new(:subject => "some messages")
      end

      service_account_response = response_hash[:service_account]
      service_account_response[:configuration_required].should be true
      service_account_response[:configuration_url].should eq "some config url"
      service_account_response[:provisioned_services_url].should eq "some provision url"
      service_account_response[:url].should eq "some resource url"
      response_hash[:message].should eq({:message_type => 'status', :subject => "some messages", :body => nil})
    end

    it "can send a message to the customer" do
      api_token = @service_account_hash[:service][:partner][:api_token]

      @connection = EY::ServicesAPI::Connection.new(api_token)

      @connection.send_message(@service_account.messages_url, EY::ServicesAPI::StatusMessage.new(:subject => "another messages", :body => "with some content"))

      latest_status_message = @tresfiestas.latest_status_message
      latest_status_message[:subject].should eq "another messages"
      latest_status_message[:body].should eq "with some content"
    end
  end

end