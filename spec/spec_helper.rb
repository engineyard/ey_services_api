require 'ey_services_api'
require 'rspec'

RSpec.configure do |config|
  config.before(:each) do
    if ENV["BUNDLE_GEMFILE"] == "InternalGemfile"
      require 'tresfiestas/gem_integration_test'
      EY::ServicesAPI.enable_mock!(Tresfiestas::GemIntegrationTest)
    else
      EY::ServicesAPI.enable_mock!
    end
    @tresfiestas = EY::ServicesAPI.mock_backend
  end
end
