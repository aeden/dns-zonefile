require 'spec_helper'
require 'dns/resource_record/soa'

describe "DNS::ResourceRecord::SOA" do
  it "should have a nameserver" do
    DNS::ResourceRecord::SOA.new.should respond_to(:ns)
  end

  it "should have a responsible person" do
    DNS::ResourceRecord::SOA.new.should respond_to(:rp)
  end

  it "should have a serial" do
    DNS::ResourceRecord::SOA.new.should respond_to(:serial)
  end

  it "should have a refresh time" do
    DNS::ResourceRecord::SOA.new.should respond_to(:refresh)
  end

  it "should have a retry time" do
    DNS::ResourceRecord::SOA.new.should respond_to(:retry)
  end

  it "should have an expiry time" do
    DNS::ResourceRecord::SOA.new.should respond_to(:expires)
  end

  it "should have a time-to-live" do
    DNS::ResourceRecord::SOA.new.should respond_to(:ttl)
  end
end