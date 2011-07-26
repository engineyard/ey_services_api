require 'ey_services_api'
require 'tresfiestas/gem_integration_test'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

shared_context "tresfiestas setup" do
  before(:all) do
    backend = Tresfiestas::GemIntegrationTest
    @tresfiestas = backend.setup!
  end

  before do
    @tresfiestas.reset!
  end
end

shared_context "tresfiestas connection" do
  before do
    @partner = @tresfiestas.create_partner

    @registration_url = @partner[:registration_url]
    @api_secret = @partner[:api_secret]

    @registration_params = EY::ServicesAPI::Service.dummy_attributes
    @connection = EY::ServicesAPI::Connection.new(@registration_url, @api_secret)
  end
end

shared_context "tresfiestas service" do
  include_context 'tresfiestas connection'

  before do
    @service = @connection.register_service(@registration_params)
  end
end