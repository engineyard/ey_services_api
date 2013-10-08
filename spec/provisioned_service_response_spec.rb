require 'rspec'

describe EY::ServicesAPI::ProvisionedServiceResponse do

  describe "#to_hash" do
    let(:url) { "some url" }
    let(:vars) { [ 'var1', 'var2' ] }
    let(:configuration_url) { "some config url" }

    context "v1" do
      let(:configuration_required) { true }
      let(:message) { { body: "Some text" } }
      let(:message_obj) { double(:to_hash => message) }
      let(:params) {
        {
          url: url,
          configuration_required: configuration_required,
          configuration_url: configuration_url,
          vars: vars,
          message: message
        }
      }
      let(:expected_result) {
        {
          provisioned_service: {
            url: url,
            configuration_required: configuration_required,
            configuration_url: configuration_url,
            vars: vars
          },
          message: message
        }
      }

      it 'should return a hash with the correct keys' do
        EY::ServicesAPI::ProvisionedServiceResponse.new(params).to_hash.should eq expected_result

        EY::ServicesAPI::ProvisionedServiceResponse.new(params.merge(api_version: 1)).to_hash.should eq expected_result
      end
    end

    context "v2" do
      let(:url) { "some url" }
      let(:vars) { [ 'var1', 'var2' ] }
      let(:configuration_url) { "some config url" }
      let(:params) {
        {
          url: url,
          configuration_url: configuration_url,
          vars: vars,
          api_version: 2
        }
      }
      let(:expected_result) {
        {
          resource: {
            url: url,
            configuration_url: configuration_url,
            vars: vars
          }
        }
      }

      it 'should return a hash with the correct keys' do
        EY::ServicesAPI::ProvisionedServiceResponse.new(params).to_hash.should eq expected_result
      end
    end
  end
end