require 'spec_helper'
require 'sinatra'

describe EY::ServicesAPI::ServiceAccountCreation do

  describe "with a service account created" do
    before do
      @service_account_hash = @tresfiestas.service_account[:pushed_service_account]
    end

    it "got the right attributes" do
      standard_response_params = @tresfiestas.actor(:service_provider).service_account_creation_params
      @service_account_hash[:configuration_required].should eq standard_response_params[:configuration_required]
      @service_account_hash[:configuration_url].should eq standard_response_params[:configuration_url]
      @service_account_hash[:provisioned_services_url].should eq standard_response_params[:provisioned_services_url]
      @service_account_hash[:url].should eq standard_response_params[:url]
      status_message = @tresfiestas.latest_status_message
      status_message.should_not be_nil
      status_message[:subject].should eq "some messages"
    end

    describe "updating a service account" do
      before do
        @connection = EY::ServicesAPI.connection
        service_account = @tresfiestas.service_account
        @connection.update_service_account(service_account[:url], {:configuration_required => true, :configuration_url => "a different url"})
      end

      it "works" do
        pushed_service = @tresfiestas.service_account[:pushed_service_account]
        pushed_service[:configuration_url].should eq "a different url"
        pushed_service[:configuration_required].should eq true
      end
    end

  end
end