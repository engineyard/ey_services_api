require 'spec_helper'
require 'sinatra'

describe EY::ServicesAPI::Service do

  before do
    @valid_params = EY::ServicesAPI::Service.dummy_attributes
    @service = EY::ServicesAPI::Service.new(@valid_params)
  end
  
  it "can be initialized with a hash" do
    @service.should be_a EY::ServicesAPI::Service
    @service.name.should eq @valid_params[:name]
    @service.description.should eq @valid_params[:description]
    @service.service_accounts_url.should eq @valid_params[:service_accounts_url]
    @service.home_url.should eq @valid_params[:home_url]
    @service.terms_and_conditions_url.should eq @valid_params[:terms_and_conditions_url]
    @service.vars.should eq @valid_params[:vars]
  end

  #TODO: how can we genericise this setup
  [Tresfiestas::GemIntegrationTest].each do |backend|
    describe "with #{backend} backend" do
      before(:all) do
        @tresfiestas = backend.setup!
      end
      before do
        @tresfiestas.reset!
      end

      describe "with a registration_url and api_secret" do
        before do
          partner = @tresfiestas.create_partner

          @registration_url = partner[:registration_url]
          @api_secret = partner[:api_secret]

          @registration_params = EY::ServicesAPI::Service.dummy_attributes
          @connection = EY::ServicesAPI::Connection.new(@registration_url, @api_secret)
        end

        it "can register a service" do
          service = @connection.register_service(@registration_params)
          service.should be_a EY::ServicesAPI::Service
          service.url.should_not be_nil
        end

        it "can handle errors on registration" do
          lambda{ 
            @connection.register_service(@registration_params.merge(:name => nil))
          }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Name can't be blank/)
        end

        describe "with a registered service" do
          before do
            @service = @connection.register_service(@registration_params)
          end

          it "can fetch your service" do
            fetched_service = @connection.get_service(@service.url)
            fetched_service.should eq @service
          end

          it "can update your service" do
            new_name = "New and Improved: #{@service.name}"
            @service.update(:name => new_name)
            @service.name.should eq new_name
            fetched_service = @connection.get_service(@service.url)
            fetched_service.name.should eq new_name
          end

          it "can handle errors when updating your service" do
            old_name = @service.name
            lambda {
              @service.update(:name => nil)
            }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Name can't be blank/)
            @service.name.should eq old_name
            fetched_service = @connection.get_service(@service.url)
            fetched_service.name.should eq old_name
          end

          it "can delete your service" do
            @service.destroy
            lambda {
              @connection.get_service(@service.url)
            }.should raise_error EY::ServicesAPI::Connection::NotFound
          end

          describe "with an AWSM account id" do
            before do
              
            end
          end
        end
      end
    end
  end
end