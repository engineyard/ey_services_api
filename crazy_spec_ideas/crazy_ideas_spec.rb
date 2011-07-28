
class ServiceCreationTest < Sinatra::Base
  
  post "/register_service_account" do
    request_json = request.body.read
    service_account = EY::ServicesAPI::ServiceAccount.create_from_request(request_json)

    Assertions.make! "handling the request" do
      request_hash = JSON.parse(request_json)
      service_account.url.should eq request_hash['url']
      service_account.messages_url.should eq request_hash['messages_url']
      service_account.invoices_url.should eq request_hash['invoices_url']
      service_account.name.should eq request_hash['name']
    end

    response_hash = service_account.creation_response_hash do |presenter|
      presenter.provisioned_services_url = "some provision url"
      presenter.url = "some resource url"
      presenter.configuration_required = true
      presenter.configuration_url = "some config url" #doesn't even have to be valid here!
      presenter.message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => "some messages")
    end

    Assertions.make! "making the response" do
      service_account_response = response_hash[:service_account]
      service_account_response[:configuration_required].should be true
      service_account_response[:configuration_url].should eq "some config url"
      service_account_response[:provisioned_services_url].should eq "some provision url"
      service_account_response[:url].should eq "some resource url"
      response_hash[:message].should eq({:message_type => 'status', :subject => "some messages", :body => nil})
    end

    response_hash.to_json
  end

end

it "tests service account creation" do
  service_account = @tresfiestas.create_service_account(ServiceCreationTest.new, "/register_service_account")
  service_account.provisioned_services_url.should eq "some provision url"
  service_account.provisioned_services_url
end


class ServiceCreationTest < Sinatra::Base
  class << self
    attr_accessor :latest_customer
  end
    
  post "/create_customer" do
    request_json = request.body.read
    service_account = EY::ServicesAPI::ServiceAccount.create_from_request(request_json)

    ServiceAccount.latest_customer = service_account

    service_account.creation_response_hash do |presenter|
      presenter.provisioned_services_url = "some provision url"
      presenter.url = "some resource url"
      presenter.configuration_required = true
      presenter.configuration_url = "some config url" #doesn't even have to be valid here!
      presenter.message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => "some messages")
    end.to_json
  end

end

it "tests service account creation" do
  service_account = @tresfiestas.create_service_account(ServiceCreationTest.new, "/create_customer")
  service_account[:provisioned_services_url].should eq "some provision url"
  service_account[:configuration_url].should eq "configuration_required"
  #...

  created_customer = ServiceCreationTest.latest_customer
  created_customer.name.should eq service_account[:name]
  #...
end


it "can send messages" do
  service_account = @tresfiestas.create_service_account(ServiceCreationTest.new, "/create_customer")
  created_customer = ServiceCreationTest.latest_customer
  connection = ServiceCreationTest.get_connection

  connection.send_message(created_customer.messages_url, 
    EY::ServicesAPI::Message.new(:message_type => "status", :subject => "another messages", :body => "with some content"))

  latest_status_message = @tresfiestas.latest_status_message
  latest_status_message[:subject].should eq "another messages"
  latest_status_message[:body].should eq "with some content"

end
