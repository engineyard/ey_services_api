require 'sinatra/base'

module EyServicesFake
  class TresfiestasFakeRackApp < Sinatra::Base
    enable :raise_errors
    disable :dump_errors
    disable :show_exceptions

    class << self
      attr_accessor :partner_connection
      attr_accessor :awsm_connection
    end

    ################
    # External API #
    ################

    get '/api/1/partners/:partner_id/services' do |partner_id|
      partner = Partner.get!(partner_id)
      to_return = []
      partner.services.each do |service|
        to_return << {"service" => service.attributes.merge('url' => URL_GEN.service(service)) }
      end
      to_return.to_json
    end

    #TODO: auth!
    post '/api/1/partners/:partner_id/services' do |partner_id|
      partner = Partner.get!(partner_id)
      service_json = JSON.parse(request.body.read)["service"]
      if service_json["name"].to_s.empty?
        status 400
        {:error_messages => ["Name can't be blank"]}.to_json
      else
        service = Service.create(service_json.merge(:partner_id => partner.id))
        status 201
        headers 'Location' => URL_GEN.service(service)
        {}.to_json
      end
    end

    get '/api/1/partners/:partner_id/services/:service_id' do |partner_id, service_id|
      partner = Partner.get!(partner_id)
      if service = partner.services.detect{ |s| s.id.to_s == service_id.to_s }
        {"service" => service.attributes}.to_json
      else
        status 404
        {}.to_json
      end
    end

    put '/api/1/partners/:partner_id/services/:service_id' do |partner_id, service_id|
      partner = Partner.get!(partner_id)
      service = partner.services.detect{ |s| s.id.to_s == service_id.to_s }
      update_params = JSON.parse(request.body.read)["service"]
      if update_params.key?("name") && update_params["name"].to_s.empty?
        status 400
        {:error_messages => ["Name can't be blank"]}.to_json
      else
        service.update_attributes(update_params)
        {}.to_json
      end
    end

    delete '/api/1/partners/:partner_id/services/:service_id' do |partner_id, service_id|
      partner = Partner.get!(partner_id)
      service = partner.services.detect{ |s| s.id.to_s == service_id.to_s }
      service.destroy
      {}.to_json
    end

    put '/api/1/partners/:partner_id/services/:service_id/service_accounts/:service_account_id' do |partner_id, service_id, service_account_id|
      partner = Partner.get!(partner_id)
      service = partner.services.detect{ |s| s.id.to_s == service_id.to_s }
      service_account = service.service_accounts.detect{ |sa| sa.id.to_s == service_account_id.to_s }
      service_account_atts = JSON.parse(request.body.read)["service_account"]
      service_account.update_attributes(service_account_atts)
      {}.to_json
    end

    put '/api/1/service_accounts/:service_account_id/provisioned_service/:provisioned_service_id' do |service_account_id, provisioned_service_id|
      service_account = ServiceAccount.get!(service_account_id)
      provisioned_service = service_account.provisioned_services.detect{ |ps| ps.id.to_s == provisioned_service_id.to_s}
      atts = JSON.parse(request.body.read)["provisioned_service"]
      provisioned_service.update_attributes(atts)
      {}.to_json
    end

    post '/api/1/partners/:partner_id/services/:service_id/service_accounts/:service_account_id/invoices' do |partner_id, service_id, service_account_id|
      invoice_params = JSON.parse(request.body.read)["invoice"]
      unless invoice_params['total_amount_cents'].is_a?(Fixnum)
        status 400
        return {:error_messages => ["Total Amount Cents must be an integer"]}.to_json
      end
      if invoice_params["line_item_description"].to_s.empty?
        status 400
        return {:error_messages => ["Line item description can't be blank"]}.to_json
      end
      if invoice_params['total_amount_cents'] < 0
        status 400
        return {:error_messages => ["Total amount cents must be greater than or equal to 0"]}.to_json
      end
      Invoice.create(invoice_params.merge(:service_account_id => service_account_id.to_i))
      {}.to_json
    end

    post '/api/1/partners/:partner_id/services/:service_id/service_accounts/:service_account_id/messages' do |partner_id, service_id, service_account_id|
      message_params = JSON.parse(request.body.read)["message"]
      message_type = message_params['message_type']
      subject = message_params['subject']
      body = message_params['body']
      
      if subject.to_s.empty?
        status 400
        return {:error_messages => ["Subject can't be blank."]}.to_json
      end

      unless ['status', 'notification', 'alert'].include? message_type
        status 400
        return {:error_messages => ['Message type must be one of: status, notification or alert']}.to_json
      end

      service_account = ServiceAccount.get(service_account_id)
      message = Message.create(message_params.merge(:service_account_id => service_account.id))
      self.class.awsm_connection.post(service_account.dashboard_notifications_url, {
        :notification => {:subject => subject, :body => body},
        :message_type => message_type,
        :configuration_possible => !!service_account.configuration_url,
        :service_name => service_account.service.name,
        :service_id => service_account.service_id})
      {}.to_json
    end

    post '/api/1/partners/:partner_id/services/:service_id/service_accounts/:service_account_id/provisioned_service/:provisioned_service_id/messages' do |partner_id, service_id, service_account_id, provisioned_service_id|
      message_params = JSON.parse(request.body.read)["message"]
      subject = message_params['subject']
      message_type = message_params['message_type']
      body = message_params['body']

      if subject.to_s.empty?
        status 400
        return {:error_messages => ["Subject can't be blank."]}.to_json
      end

      unless ['status', 'notification', 'alert'].include? message_type
        status 400
        return {:error_messages => ['Message type must be one of: status, notification or alert']}.to_json
      end

      message = Message.create(message_params.merge(:provisioned_service_id => provisioned_service_id.to_i))
      provisioned_service = ProvisionedService.get(provisioned_service_id)
      service_account = provisioned_service.service_account
      message = Message.create(message_params.merge(:provisioned_service_id => provisioned_service.id))
      self.class.awsm_connection.post(provisioned_service.dashboard_notifications_url, {
        :notification => {:subject => subject, :body => body},
        :message_type => message_type,
        :configuration_possible => !!provisioned_service.configuration_url,
        :service_name => service_account.service.name,
        :provisionable_service_id => provisioned_service.id})
      {}.to_json
    end

  end
end
