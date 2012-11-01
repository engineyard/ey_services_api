#because there may be multiple 'spec_helper' in load path when running from external test helper
require File.expand_path('../spec_helper.rb', __FILE__)
require 'timecop'

describe EY::ServicesAPI::Invoice do
  before do
    @service_account = @tresfiestas.service_account
    @invoices_url = @service_account[:invoices_url]
    @connection = EY::ServicesAPI.connection
    Timecop.return
  end
  after do
    Timecop.return
  end

  it "can send an invoice" do
    invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 500, :line_item_description => "good stuff")
    @connection.send_invoice(@invoices_url, invoice)
    latest_invoice = @tresfiestas.latest_invoice
    latest_invoice[:total_amount_cents].should eq 500
    latest_invoice[:line_item_description].should eq "good stuff"
    latest_invoice[:service_account_id].should eq @service_account[:id]
  end

  it "duplicate blank uniq identifiers don't cause conflicts" do
    invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 500, :line_item_description => "good stuff", :unique_id => "")
    @connection.send_invoice(@invoices_url, invoice)
    invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 5000, :line_item_description => "duplicate stuff ok", :unique_id => "")
    @connection.send_invoice(@invoices_url, invoice)
  end

  internal_only_tests do

    it "can send an invoice with uniq identifier, returns error for duplicates" do
      invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 500, :line_item_description => "good stuff", :unique_id => "ABCDEFG123")
      @connection.send_invoice(@invoices_url, invoice)
      lambda{
        invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 5000, :line_item_description => "duplicate stuff BAD", :unique_id => "ABCDEFG123")
        @connection.send_invoice(@invoices_url, invoice)
      }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Unique ID already exists on another invoice on this account/)
    end

  end

  it "can list invoices, can delete pending invoices" do
    invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 500, :line_item_description => "good stuff", :unique_id => 123)
    @connection.send_invoice(@invoices_url, invoice)
    invoices = @connection.list_invoices(@invoices_url)
    invoices.size.should eq 1
    invoice = invoices.first
    invoice.total_amount_cents.should eq 500
    invoice.line_item_description.should eq "good stuff"
    invoice.unique_id.should eq "123"
    invoice.status.should eq "pending"
    invoice.destroy
    @connection.list_invoices(@invoices_url).size.should eq 0
  end

  internal_only_tests do

    it "can list invoices, can delete pending invoices on the first of the month" do
      Timecop.travel(Time.now.beginning_of_month + 12.hours)
      invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 500, :line_item_description => "good stuff", :unique_id => 123)
      @connection.send_invoice(@invoices_url, invoice)
      invoices = @connection.list_invoices(@invoices_url)
      invoices.size.should eq 1
      invoice = invoices.first
      invoice.total_amount_cents.should eq 500
      invoice.line_item_description.should eq "good stuff"
      invoice.unique_id.should eq "123"
      invoice.status.should eq "pending"
      invoice.destroy
      @connection.list_invoices(@invoices_url).size.should eq 0
    end

    it "invoices become locked 24 hours after the account is canceled, can't be deleted" do
      @tresfiestas.destroy_service_account
      invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 500, :line_item_description => "good stuff", :unique_id => 123)
      @connection.send_invoice(@invoices_url, invoice)
      Timecop.travel(Time.now + 1.day + 1.minute)
      invoices = @connection.list_invoices(@invoices_url)
      invoices.size.should eq 1
      invoice = invoices.first
      invoice.total_amount_cents.should eq 500
      invoice.line_item_description.should eq "good stuff"
      invoice.unique_id.should eq "123"
      invoice.status.should eq "locked"
      lambda{
        invoice.destroy
      }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /cannot delete locked invoices/)
    end

    it "invoices become locked 24 after end of month, and 24 hours after the account is canceled, can't be deleted" do
      invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 500, :line_item_description => "good stuff", :unique_id => 123)
      @connection.send_invoice(@invoices_url, invoice)
      Timecop.travel(Time.now.end_of_month + 1.day + 1.minute)
      invoices = @connection.list_invoices(@invoices_url)
      invoices.size.should eq 1
      invoice = invoices.first
      invoice.total_amount_cents.should eq 500
      invoice.line_item_description.should eq "good stuff"
      invoice.unique_id.should eq "123"
      invoice.status.should eq "locked"
      lambda{
        invoice.destroy
      }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /cannot delete locked invoices/)
    end

    it "returns an error when posting invoices to canceled service accounts" do
      @tresfiestas.destroy_service_account
      invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 500, :line_item_description => "good stuff")
      @connection.send_invoice(@invoices_url, invoice)

      Timecop.travel(Time.now + 1.day + 1.minute)
      lambda{
        invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 500, :line_item_description => "good stuff")
        @connection.send_invoice(@invoices_url, invoice)
      }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Account is no longer active, and cannot accept any invoices/)
    end

  end

  it "returns an error for fractional ammounts for total_amount_cents" do
    lambda{
      invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 4.50, :line_item_description => "fractional stuff")
      @connection.send_invoice(@invoices_url, invoice)
    }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Total Amount Cents must be an integer/)
  end

  it "allows invoices for zero cents" do
    lambda{
      invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 0, :line_item_description => "free stuff")
      @connection.send_invoice(@invoices_url, invoice)
    }.should_not raise_error
  end

  it "returns an error for negative ammounts for total_amount_cents" do
    lambda{
      invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => -1, :line_item_description => "bad stuff")
      @connection.send_invoice(@invoices_url, invoice)
    }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Total amount cents must be greater than or equal to 0/)
  end

  it "returns an error for blank descriptions" do
    lambda{
      invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 10, :line_item_description => "")
      @connection.send_invoice(@invoices_url, invoice)
    }.should raise_error(EY::ServicesAPI::Connection::ValidationError, /Line item description can't be blank/)
  end

end