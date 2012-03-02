module EY
  module ServicesAPI
    module ExternalTestHelper
      def self.rspec_pattern
        File.expand_path('../../../spec', __FILE__).to_s + "/**/*_spec.rb"
      end
    end
  end
end
