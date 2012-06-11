require 'cubbyhole/base'

module EyServicesFake
  class Model < Cubbyhole::Base
    def self.inherited(klass)
      decendants << klass
    end
    class << self
      attr_accessor :current_id
    end
    self.current_id = 0
    def self.next_id
      Model.current_id += 1
    end
    def self.nuke_all
      decendants.map(&:nuke)
    end
    def self.backend
      @backend ||= Hash.new
    end
    def self.decendants
      @decendants ||= []
    end
    def self.belongs_to(model, name, key)
      search_context = self.to_s.split("::")
      search_context.pop
      search_context = eval(search_context.join("::").to_s)
      self.class_eval do
        define_method(name) do
          klass = search_context.const_get(model)
          klass.all.find{|s| self.send(key).to_i == s.id.to_i }
        end
      end
    end
    def self.has_many(model, name, key)
      search_context = self.to_s.split("::")
      search_context.pop
      search_context = eval(search_context.join("::").to_s)
      self.class_eval do
        define_method(name) do
          klass = search_context.const_get(model)
          Cubbyhole::Collection.new(klass.all.select{|s| s.send(key).to_s == self.id.to_s })
        end
      end
    end
  end
  class Partner < Model
    has_many :Service, :services, :partner_id
    def self.find_by_auth_id(auth_id)
      first(:auth_id => auth_id)
    end
  end
  class Service < Model
    has_many :ServiceEnablement, :service_enablements, :service_id
    has_many :ServiceAccount, :service_accounts, :service_id
    belongs_to :Partner, :partner, :partner_id
  end
  class ServiceAccount < Model
    has_many :ProvisionedService, :provisioned_services, :service_account_id
    has_many :Message, :messages, :service_account_id
    belongs_to :Service, :service, :service_id
    has_many :Invoice, :invoices, :service_account_id
  end
  class ProvisionedService < Model
    has_many :Message, :messages, :provisioned_service_id
    belongs_to :ServiceAccount, :service_account, :service_account_id
  end
  class ServiceEnablement < Model; end
  class Invoice < Model
    belongs_to :ServiceAccount, :service_account, :service_account_id
  end
  class Message < Model
    belongs_to :ServiceAccount, :service_account, :service_account_id
    belongs_to :ProvisionedService, :provisioned_service, :provisioned_service_id
  end
  class Awsm < Model; end
end
