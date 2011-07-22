require 'spec_helper'
require 'sinatra'

describe EY::ServicesAPI::Connection do
  before do
    @registration_url = 'http://example.com/register'
    @api_secret = '123abc'
  end
  it "can be created with registration_url and api_secret" do
    connection = EY::ServicesAPI::Connection.new(@registration_url, @api_secret)
    connection.registration_url.should eq @registration_url
    connection.api_secret.should eq @api_secret
  end

  class RackApp < Sinatra::Base
    post "/register" do
      {}.to_json
    end
  end

  describe "with a connection" do
    before do
      @connection = EY::ServicesAPI::Connection.new(@registration_url, @api_secret)
      @connection.backend = RackApp
    end

    it "can register a service" do
      valid_params = EY::ServicesAPI::Service.dummy_attributes
      service = @connection.register_service(valid_params)
      service.should eq EY::ServicesAPI::Service.new(valid_params)
      # 
      # service_yaml = service.to_yaml
      # EY::ServicesAPI::Service.load_from_yaml(service_yaml)
    end
  end
end