#because there may be multiple 'spec_helper' in load path when running from external test helper
require File.expand_path('../spec_helper.rb', __FILE__)

describe EY::ServicesAPI::Invoice do
  before do
    @service_account = @tresfiestas.service_account
    @invoices_url = @service_account[:invoices_url]
    @connection = EY::ServicesAPI.connection
  end

  it "can send an invoice" do
    invoice = EY::ServicesAPI::Invoice.new(:total_amount_cents => 500, :line_item_description => "good stuff")
    @connection.send_invoice(@invoices_url, invoice)
    latest_invoice = @tresfiestas.latest_invoice
    latest_invoice[:total_amount_cents].should eq 500
    latest_invoice[:line_item_description].should eq "good stuff"
    latest_invoice[:service_account_id].should eq @service_account[:id]
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