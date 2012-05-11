#because there may be multiple 'spec_helper' in load path when running from external test helper
require File.expand_path('../spec_helper.rb', __FILE__)

describe EY::ServicesAPI::ServiceAccountCreation do

  describe "attributes given in service account creation" do
    before do
      class SaveThis
        class << self
          attr_accessor :stuff
        end
      end
      EyServicesFake::MockingBirdService.service_account_creation_handler = Proc.new do
        SaveThis.stuff = EY::ServicesAPI::ServiceAccountCreation.from_request(request.body.read)
        {}.to_json
      end
    end
    it "matches" do
      @service_account_hash = @tresfiestas.service_account
      service_account = SaveThis.stuff
      service_account.name.should eq @service_account_hash[:name]
      URI.parse(service_account.url).path.should eq URI.parse(@service_account_hash[:url]).path
      URI.parse(service_account.messages_url).path.should eq URI.parse(@service_account_hash[:messages_url]).path
      URI.parse(service_account.invoices_url).path.should eq URI.parse(@service_account_hash[:invoices_url]).path
    end
  end

  describe "with all possible attributes returned" do
    before do
      EyServicesFake::MockingBirdService.service_account_creation_handler = Proc.new do
        service_account = EY::ServicesAPI::ServiceAccountCreation.from_request(request.body.read)
        EY::ServicesAPI::ServiceAccountResponse.new(
          :provisioned_services_url => "some provinioning url",
          :url                      => "some resource url",
          :configuration_url        => "some configuration url",
          :configuration_required   => true,
          :message                  => EY::ServicesAPI::Message.new(:message_type => "status", :subject => "some message or something")
        ).to_hash.to_json
      end
    end
    it "works" do
      @service_account_hash = @tresfiestas.service_account[:pushed_service_account]
      @service_account_hash[:configuration_required].should eq true
      @service_account_hash[:configuration_url].should eq "some configuration url"
      @service_account_hash[:provisioned_services_url].should eq "some provinioning url"
      @service_account_hash[:url].should eq "some resource url"
      status_message = @tresfiestas.latest_status_message
      status_message.should_not be_nil
      status_message[:subject].should eq "some message or something"
    end
  end

  describe "with no attributes returned" do
    before do
      EyServicesFake::MockingBirdService.service_account_creation_handler = Proc.new do
        EY::ServicesAPI::ServiceAccountResponse.new.to_hash.to_json
      end
    end
    it "works" do
      @service_account_hash = @tresfiestas.service_account[:pushed_service_account]
      @service_account_hash[:configuration_required].should be_nil
      @service_account_hash[:configuration_url].should be_nil
      @service_account_hash[:provisioned_services_url].should be_nil
      @service_account_hash[:url].should be_nil
      status_message = @tresfiestas.latest_status_message
      status_message.should be_nil
    end
  end

  describe "rejecting the creation request gracefully" do
    before do
      EyServicesFake::MockingBirdService.service_account_creation_handler = Proc.new do
        status 400
        {:error_messages => ["This service is not currently supported for trial customers"]}.to_json
      end
    end
    it "works" do
      raised_error = nil
      begin
        @tresfiestas.service_account
      rescue EY::ApiHMAC::BaseConnection::ValidationError => e
        raised_error = e
      end
      raised_error.should_not be_nil
      raised_error.error_messages.should eq ["This service is not currently supported for trial customers"]
    end
  end

  describe "with a service account created" do
    before do
      @service_account_hash = @tresfiestas.service_account[:pushed_service_account]
    end

    it "got the right attributes" do
      standard_response_params = @tresfiestas.actor(:service_provider).service_account_creation_params(123)
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