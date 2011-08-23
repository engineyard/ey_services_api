class TresfiestasFake
  BASE_URL = "http://mockservice.test"

  def self.setup!
  end
  def self.reset!
  end

  def self.mock_helper
    TestHelper
  end

  class TestHelper
    def self.reset!
    end

    def self.create_partner
      {
        :registration_url => "#{BASE_URL}/api/1/register_a_new_service",
        :auth_id => "123",
        :auth_key => "456",
      }
    end

    def self.service_registration_params
      {
        :name => "Mocking Bird", 
        :description => "a mock service", 
        :service_accounts_url =>     "#{BASE_URL}/api/1/customers/regular",
        :home_url =>                 "#{BASE_URL}/",
        :terms_and_conditions_url => "#{BASE_URL}/terms",
        :vars => [
          "MOCK_API_KEY"
        ]
      }
    end
  end

  class RackApp < Sinatra::Base
  end

end