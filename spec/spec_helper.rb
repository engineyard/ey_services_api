require 'ey_services_api'
require 'rspec'
require 'sinatra/base'

RSpec.configure do |config|
  config.before(:each) do
    if ENV["BUNDLE_GEMFILE"] == "EYIntegratedGemfile"
      require 'ey_services_fake/mocking_bird_service'
      require 'tresfiestas/gem_integration_test'
      require 'fake_awsm/test_helper'
      EY::ServicesAPI.enable_mock!(EyServicesFake::MockingBirdService.new, Tresfiestas::GemIntegrationTest.new, FakeAWSM::TestHelper.new)
    else
      require 'ey_services_fake/mocking_bird_service'
      EY::ServicesAPI.enable_mock!(EyServicesFake::MockingBirdService.new)
    end
    @tresfiestas = EY::ServicesAPI.mock_backend
  end
end

def internal_only_tests
  if ENV["BUNDLE_GEMFILE"] == "EYIntegratedGemfile"
    yield
  end
end