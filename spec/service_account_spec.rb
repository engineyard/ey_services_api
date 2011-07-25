require 'spec_helper'
require 'sinatra'

describe EY::ServicesAPI::ServiceAccount do

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

        describe "with a registered service" do
          before do
            @service = @connection.register_service(@registration_params)
          end

          it "does something" do
            #TODO
          end

        end
      end
    end
  end
end