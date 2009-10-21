require 'spec_helper'
require 'dns/zonefile'

describe "DNS::Zonefile" do
  it "should be versioned" do
    lambda {
      DNS::Zonefile.const_get(:VERSION)
    }.should_not raise_error
  end

  it "should be version 0.0.1" do
    DNS::Zonefile::VERSION.should eql("0.0.1")
  end

  it "should have an origin" do
    DNS::Zonefile.new.should respond_to(:origin)
  end

  it "should provide a way of parsing a string" do
    DNS::Zonefile.should respond_to(:parse)
  end

  describe "parsing a zonefile string" do
    before(:each) do
      @zonefile =<<-ZONE
; Hi! I'm an example zonefile.
example.com.  IN  SOA  ns.example.com. hostmaster.example.com. ( 
              2007120710 ; serial number of this zone file
              1d         ; slave refresh (1 day)
              1d         ; slave retry time in case of a problem (1 day)
              4w         ; slave expiration time (4 weeks)
              1h         ; minimum caching time in case of failed lookups (1 hour)
              )

example.com.  NS    ns                    ; ns.example.com is the nameserver for example.com
example.com.  NS    ns.somewhere.com.     ; ns.somewhere.com is a backup nameserver for example.co
example.com.  A     10.0.0.1              ; ip address for "example.com"
ns            A     10.0.0.2              ; ip address for "ns.example.com"
www           CNAME ns                    ; "www.example.com" is an alias for "ns.example.com"
wwwtest       CNAME www                   ; "wwwtest.example.com" is another alias for "www.example.com"
example.com.  MX    10 mail.example.com.  ; mail.example.com is the mailserver for example.com
example.com.  MX    10 mail.example.com.  ; mail.example.com is the mailserver for example.com
@             MX    20 mail2.example.com. ; Similar to above line, but using "@" to say "use $ORIGIN"
@             MX    50 mail3              ; Similar to above line, but using a host within this domain
ZONE
    end

    it "should set the origin correctly" do
      zone = DNS::Zonefile.parse(@zonefile)
      zone.origin.should eql('example.com.')
    end

    it "should set the SOA correctly" do
      zone = DNS::Zonefile.parse(@zonefile)
      soa = zone.soa
      soa.ns.to_s.should eql('ns.example.com.')
      soa.rp.to_s.should eql('hostmaster.example.com.')
      soa.serial.to_i.should eql(2007120710)
      soa.refresh.to_i.should eql(86400)
      soa.retry.to_i.should eql(86400)
      soa.expiry.to_i.should eql(2419200)
      soa.ttl.to_i.should eql(3600)
    end
  end
end
