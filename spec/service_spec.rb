require 'spec_helper'

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
end