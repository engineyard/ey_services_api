require 'ey_services_api'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

shared_context "tresfiestas setup" do

  before do
    if ENV["BUNDLE_GEMFILE"] == "InternalGemfile"
      require 'tresfiestas/gem_integration_test'
      EY::ServicesAPI.enable_mock!(Tresfiestas::GemIntegrationTest)
    else
      EY::ServicesAPI.enable_mock!
    end
    @tresfiestas = EY::ServicesAPI.mock_backend
  end

end
