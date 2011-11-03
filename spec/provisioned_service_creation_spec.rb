require 'spec_helper'
require 'sinatra'

describe EY::ServicesAPI::ProvisionedServiceCreation do

  describe "with a service account created" do
    before do
      @service_account_hash = @tresfiestas.service_account[:pushed_service_account]
    end

    describe "with a provisioned service" do
      before do
        @pushed_provisioned_service = @tresfiestas.provisioned_service[:pushed_provisioned_service]
      end

      it "should have been provisioned correctly" do
        standard_response_params = @tresfiestas.actor(:service_provider).service_provisioned_params
        @pushed_provisioned_service[:configuration_required].should eq standard_response_params[:configuration_required]
        @pushed_provisioned_service[:configuration_url].should eq standard_response_params[:configuration_url]
        @pushed_provisioned_service[:provisioned_services_url].should eq standard_response_params[:provisioned_services_url]
        @pushed_provisioned_service[:url].should eq standard_response_params[:url]
        status_message = @tresfiestas.latest_status_message
        status_message.should_not be_nil
        status_message[:subject].should eq "some provisioned service messages"
      end

      describe "updating a provisioned service" do
        before do
          @connection = EY::ServicesAPI.connection
          provisioned_service = @tresfiestas.provisioned_service
          @connection.update_provisioned_service(provisioned_service[:url],
                                                 :configuration_required => true,
                                                 :configuration_url => "something else")
        end

        it "works" do
          pushed = @tresfiestas.provisioned_service[:pushed_provisioned_service]
          pushed[:configuration_url].should eq "something else"
          pushed[:configuration_required].should eq true
        end
      end

    end
  end

end