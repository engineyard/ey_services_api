module EyServicesFake
  class UrlGenerator

    def initialize(base_url)
      @base_url = base_url
    end

    def service_registration(partner)
      "#{@base_url}/api/1/partners/#{partner.id}/services"
    end

    def service(service)
      "#{@base_url}/api/1/partners/#{service.partner_id}/services/#{service.id}"
    end

    def partner_service_account(service, service_account)
      "#{@base_url}/api/1/partners/#{service.partner_id}/services/#{service.id}/service_accounts/#{service_account.id}"
    end

    def messages(service, service_account, provisioned_service = nil)
      if provisioned_service
        "#{@base_url}/api/1/partners/#{service.partner_id}/services/#{service.id}/service_accounts/#{service_account.id}/provisioned_service/#{provisioned_service.id}/messages"
      else
        "#{@base_url}/api/1/partners/#{service.partner_id}/services/#{service.id}/service_accounts/#{service_account.id}/messages"
      end
    end

    def invoices(service, service_account)
      "#{@base_url}/api/1/partners/#{service.partner_id}/services/#{service.id}/service_accounts/#{service_account.id}/invoices"
    end

    def invoice(service, service_account, invoice)
      "#{@base_url}/api/1/partners/#{service.partner_id}/services/#{service.id}/service_accounts/#{service_account.id}/invoices/#{invoice.id}"
    end

    def partner_provisioned_service(service_account, provisioned_service)
      "#{@base_url}/api/1/service_accounts/#{service_account.id}/provisioned_service/#{provisioned_service.id}"
    end

  end
end
