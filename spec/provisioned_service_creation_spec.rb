require 'spec_helper'
require 'sinatra'

describe EY::ServicesAPI::ProvisionedServiceCreation do

  describe "attributes given in service provisioning" do
    before do
      class SaveThis
        class << self
          attr_accessor :stuff
        end
      end
      EyServicesFake::MockingBirdService.service_provisioning_handler = Proc.new do
        SaveThis.stuff = EY::ServicesAPI::ProvisionedServiceCreation.from_request(request.body.read)
        {}.to_json
      end
    end
    it "matches" do
      @provisioned_service_hash = @tresfiestas.provisioned_service
      provisioned_service = SaveThis.stuff
      app_deployment = @provisioned_service_hash[:app_deployment]
      provisioned_service.environment.id.should eq app_deployment[:environment][:id]
      provisioned_service.environment.name.should eq app_deployment[:environment][:name]
      provisioned_service.environment.framework_env.should eq app_deployment[:environment][:framework_env]
      provisioned_service.app.id.should eq app_deployment[:app][:id]
      provisioned_service.app.name.should eq app_deployment[:app][:name]
      provisioned_service.messages_url.should eq @provisioned_service_hash[:messages_url]
    end
  end

  describe "with all possible attributes returned" do
    before do
      EyServicesFake::MockingBirdService.service_provisioning_handler = Proc.new do
        provisioned_service = EY::ServicesAPI::ProvisionedServiceCreation.from_request(request.body.read)
        EY::ServicesAPI::ProvisionedServiceResponse.new(
          :url                    => "some url",
          :vars                   => {'some_key' => "some value"},
          :configuration_required => "true or false",
          :configuration_url      => "some configuration url",
          :message                => EY::ServicesAPI::Message.new(:message_type => "status", :subject => "some provisioned service message or something")
        ).to_hash.to_json
      end
    end
    it "works" do
      @pushed_provisioned_service = @tresfiestas.provisioned_service[:pushed_provisioned_service]
      @pushed_provisioned_service[:url].should eq "some url"
      @pushed_provisioned_service[:vars].should eq({'some_key' => "some value"})
      @pushed_provisioned_service[:configuration_required].should eq "true or false"
      @pushed_provisioned_service[:configuration_url].should eq "some configuration url"
      status_message = @tresfiestas.latest_status_message
      status_message.should_not be_nil
      status_message[:subject].should eq "some provisioned service message or something"
    end
  end

  describe "with no attributes returned" do
    before do
      EyServicesFake::MockingBirdService.service_provisioning_handler = Proc.new do
        SaveThis.stuff = EY::ServicesAPI::ProvisionedServiceCreation.from_request(request.body.read)
        EY::ServicesAPI::ProvisionedServiceResponse.new.to_hash.to_json
      end
    end
    it "works" do
      @pushed_provisioned_service = @tresfiestas.provisioned_service[:pushed_provisioned_service]
      @pushed_provisioned_service[:url].should be_nil
      @pushed_provisioned_service[:vars].should be_nil
      @pushed_provisioned_service[:configuration_required].should be_nil
      @pushed_provisioned_service[:configuration_url].should be_nil
    end
  end

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