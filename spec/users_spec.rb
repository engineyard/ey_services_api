#because there may be multiple 'spec_helper' in load path when running from external test helper
require File.expand_path('../spec_helper.rb', __FILE__)

require 'ey_services_fake/mocking_bird_service'
class UserHavingService < EyServicesFake::MockingBirdService
  def self.record_of_users
    @record_of_users ||= {}
  end

  def self.implement_the_app(app)
    super(app)
    app.class_eval do
      get "/api/1/users" do
        content_type :json
        parent.record_of_users.map do |user_id, user|
          {
            "user" => user,
            "url" => "#{parent.base_url}api/1/users/#{user_id}"
          }
        end.to_json
      end
      put "/api/1/users/:ey_user_id" do |ey_user_id|
        content_type :json
        json_post_body = JSON.parse(request.body.read)
        parent.record_of_users[ey_user_id].merge! json_post_body['user']
        {}.to_json
      end
      delete "/api/1/users/:ey_user_id" do |ey_user_id|
        content_type :json
        parent.record_of_users.delete(ey_user_id)
        {}.to_json
      end
    end
  end

  def self.account_sso_hook(params)
    @record_of_users[params["ey_user_id"]] = {
      'access_level' => params["access_level"],
      'ey_user_id' => params["ey_user_id"],
      'ey_user_email' => params["ey_user_email"],
      'ey_user_name' => params["ey_user_name"],
    }
  end

  def self.service_account_creation_params
    super.merge(:users_url => "#{base_url}api/1/users")
  end

end

describe "users" do
  describe "with a service account" do
    before do
      UserHavingService.record_of_users.clear
      @tresfiestas.actors[:service_provider] = UserHavingService.new
      @service_account = @tresfiestas.service_account
      @messages_url = @service_account[:messages_url]
      @connection = EY::ServicesAPI.connection
      @connection_to_partner_service = EY::ApiHMAC::BaseConnection.new
      @connection_to_partner_service.backend = @tresfiestas.app_for(:service_provider)
      @original_email = @tresfiestas.sso_user.email
      @ey_user_id = @tresfiestas.sso_user.external_service_id.to_s
    end

    describe "if the service doesn't provide a users_url, when a user SSOs to the service" do
      before do
        UserHavingService.record_of_users.should be_empty
        @connection.update_service_account(@service_account[:url], :users_url => nil)
        response = @connection_to_partner_service.get(@tresfiestas.service_account_sso_url)
        response.status.should eq 200
        UserHavingService.record_of_users.size.should eq 1
      end

      it "doesn't send the email" do
        UserHavingService.record_of_users[@ey_user_id]['ey_user_email'].should be_nil
      end
    end

    describe "when a user SSOs to the service" do
      before do
        UserHavingService.record_of_users.should be_empty
        response = @connection_to_partner_service.get(@tresfiestas.service_account_sso_url)
        response.status.should eq 200
        UserHavingService.record_of_users.size.should eq 1
      end

      it "saves the e-mail" do
        UserHavingService.record_of_users[@ey_user_id]['ey_user_email'].should eq @original_email
      end

      describe "when a user's e-mail changes" do
        before do
          @new_email = "new_email@example.com"
          @tresfiestas.trigger_mock_user_update(@new_email)
        end

        it "updates the saved value" do
          @new_email.should_not eq @original_email
          UserHavingService.record_of_users[@ey_user_id]['ey_user_email'].should eq @new_email
        end
      end

      describe "when a user is removed" do
        before do
          @tresfiestas.trigger_mock_user_delete
        end

        it "updates the saved value" do
          UserHavingService.record_of_users.size.should eq 0
        end
      end

    end

  end
end