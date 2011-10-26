require 'spec_helper'
require 'dns/zonefile'

describe "DNS::Zonefile" do
  it "should be versioned" do
    lambda {
      DNS::Zonefile.const_get(:VERSION)
    }.should_not raise_error
  end

  it "should be version 1.0.0" do
    DNS::Zonefile::VERSION.should eql("1.0.0")
  end

  it "should provide a way of parsing a string" do
    DNS::Zonefile.should respond_to(:parse)
  end

  describe "parsing a zonefile string" do
    before(:each) do
      @zonefile =<<-ZONE
; Hi! I'm an example zonefile.
$ORIGIN example.com.
$TTL 86400; expire in 1 day.
$OTHER abc
; line above has spaces at the end, but no comment
@             IN  SOA  ns.example.com. hostmaster.example.com. (
              2007120710 ; serial number of this zone file
              1d         ; slave refresh (1 day)
              1d         ; slave retry time in case of a problem (1 day)
              4W         ; slave expiration time (4 weeks)
              3600       ; minimum caching time in case of failed lookups (1 hour)
              )
; That's the SOA part done.

; Next comment line has nothing after the semi-colon.
;

; Let's start the resource records.
example.com.  NS    ns                    ; ns.example.com is the nameserver for example.com
example.com.  NS    ns.somewhere.com.     ; ns.somewhere.com is a backup nameserver for example.com
example.com.  A     10.0.0.1              ; ip address for "example.com". next line has spaces after the IP, but no actual comment.
@             A     10.0.0.11
              A     10.0.0.12             ; tertiary ip for "example.com"
ns            A     10.0.0.2              ; ip address for "ns.example.com"
          60  A     10.0.0.21             ; secondary ip for "ns.example.com" with TTL
*             A     10.0.0.100            ; wildcard
*.sub         A     10.0.0.101            ; subdomain wildcard
with-class   IN  A   10.0.0.3             ; record that includes the class type of IN
with-ttl  60     A   10.0.0.5             ; with a specified TTL
ttl-class 60 IN  A   10.0.0.6             ; with TTL and class type
www           CNAME ns                    ; "www.example.com" is an alias for "ns.example.com"
wwwtest       CNAME www                   ; "wwwtest.example.com" is another alias for "www.example.com"
www2          CNAME ns.example.com.       ; yet another alias, with FQDN target

; Email... that'll be fun then
example.com.  MX    10 mail.example.com.  ; mail.example.com is the mailserver for example.com
@             MX    20 mail2.example.com. ; Similar to above line, but using "@" to say "use $ORIGIN"
@             MX    50 mail3              ; Similar to above line, but using a host within this domain

@             AAAA  2001:db8:a::1         ; IPv6, lowercase
ns            AAAA  2001:DB8:B::1         ; IPv6, uppercase
mail          AAAA  2001:db8:c::10.0.0.4  ; IPv6, with trailing IPv4-type address

sip           NAPTR 100 10 "U" "E2U+sip" "!^.*$!sip:cs@example.com!i" .   ; NAPTR record
sip2          NAPTR 100 10 "" "" "/urn:cid:.+@([^\\.]+\\.)(.*)$/\\2/i" .     ; another one

_xmpp-server._tcp   SRV   5 0 5269 xmpp-server.l.google.com.  ; SRV record

; TXT record, with embedded semicolons
_domainkey    TXT   "v=DKIM1\\;g=*\\;k=rsa\\; p=4tkw1bbkfa0ahfjgnbewr2ttkvahvfmfizowl9s4g0h28io76ndow25snl9iumpcv0jwxr2k"

@             TXT   "some other \\"message\\" goes here" ; embedded quotes
long          TXT   "a multi-segment TXT record" "usually used for really long TXT records" "since each segment can only span 255 chars"
unquoted      TXT   some text data
@             SPF   "v=spf1 a a:other.domain.com ~all"

45        IN   PTR   @

$ORIGIN test.example.com.
$TTL 3600; expire in 1 day.
@             A     10.1.0.1              ; Test with alternate origin
              MX    10  mail.example.com.
www           A     10.1.0.2              ; www.test.example.com.

ZONE
    end

    it "should set the origin correctly" do
      zone = DNS::Zonefile.parse(@zonefile)
      zone.origin.should eql('@')
    end

    it "should interpret the origin correctly" do
      zone = DNS::Zonefile.load(@zonefile)
      zone.soa.origin.should eql('example.com.')
    end

    it "should set the zone variables correctly" do
      zone = DNS::Zonefile.parse(@zonefile)
      zone.variables['TTL'].should eql('86400')
      zone.variables['ORIGIN'].should eql('example.com.')
    end

    it "should interpret the SOA correctly" do
      zone = DNS::Zonefile.load(@zonefile)
      soa = zone.soa
      soa.klass.should eql('IN')
      soa.ttl.should eql(86400)
      soa.nameserver.should eql('ns.example.com.')
      soa.responsible_party.should eql('hostmaster.example.com.')
      soa.serial.should eql(2007120710)
      soa.refresh_time.should eql(86400)
      soa.retry_time.should eql(86400)
      soa.expiry_time.should eql(2419200)
      soa.nxttl.should eql(3600)
    end

    it "should build the correct number of resource records" do
      zone = DNS::Zonefile.parse(@zonefile)
      zone.rr.size.should be(33)
    end

    it "should build the correct NS records" do
      zone = DNS::Zonefile.load(@zonefile)
      ns_records = zone.records_of DNS::Zonefile::NS
      ns_records.size.should be(2)

      ns_records.detect { |ns|
        ns.host == "example.com." && ns.nameserver == "ns.example.com."
      }.should_not be_nil

      ns_records.detect { |ns|
        ns.host == "example.com." && ns.nameserver == "ns.somewhere.com." && ns.ttl == 86400
      }.should_not be_nil
    end

    it "should build the correct A records" do
      zone = DNS::Zonefile.load(@zonefile)
      a_records = zone.records_of DNS::Zonefile::A
      a_records.size.should be(12)

      a_records.detect { |a|
        a.host == "example.com." && a.address == "10.0.0.1"
      }.should_not be_nil

      a_records.detect { |a|
        a.host == "example.com." && a.address == "10.0.0.11"
      }.should_not be_nil

      a_records.detect { |a|
        a.host == "example.com." && a.address == "10.0.0.12"
      }.should_not be_nil

      a_records.detect { |a|
        a.host == "ns.example.com." && a.address == "10.0.0.2" && a.ttl == 86400
      }.should_not be_nil

      a_records.detect { |a|
        a.host == "ns.example.com." && a.address == "10.0.0.21" && a.ttl == 60
      }.should_not be_nil

      a_records.detect { |a|
        a.host == "*.example.com." && a.address == "10.0.0.100"
      }.should_not be_nil

      a_records.detect { |a|
        a.host == "*.sub.example.com." && a.address == "10.0.0.101"
      }.should_not be_nil

      a_records.detect { |a|
        a.host == "with-class.example.com." && a.address == "10.0.0.3" && a.ttl == 86400
      }.should_not be_nil

      a_records.detect { |a|
        a.host == "with-ttl.example.com." && a.address == "10.0.0.5" && a.ttl == 60
      }.should_not be_nil

      a_records.detect { |a|
        a.host == "ttl-class.example.com." && a.address == "10.0.0.6" && a.ttl == 60
      }.should_not be_nil

      a_records.detect { |a|
        a.host == "test.example.com." && a.address == "10.1.0.1" && a.ttl == 3600
      }.should_not be_nil

      a_records.detect { |a|
        a.host == "www.test.example.com." && a.address == "10.1.0.2" && a.ttl == 3600
      }.should_not be_nil
    end

    it "should build the correct CNAME records" do
      zone = DNS::Zonefile.load(@zonefile)
      cname_records = zone.records_of DNS::Zonefile::CNAME
      cname_records.size.should be(3)

      cname_records.detect { |cname|
        cname.host == "www.example.com." && cname.target == "ns.example.com."
      }.should_not be_nil

      cname_records.detect { |cname|
        cname.host == "wwwtest.example.com." && cname.domainname == "www.example.com."
      }.should_not be_nil

      cname_records.detect { |cname|
        cname.host == "www2.example.com." && cname.domainname == "ns.example.com." && cname.ttl == 86400
      }.should_not be_nil
    end

    it "should build the correct MX records" do
      zone = DNS::Zonefile.load(@zonefile)
      mx_records = zone.records_of DNS::Zonefile::MX
      mx_records.size.should be(4)

      mx_records.detect { |mx|
        mx.host == "example.com." && mx.priority == 10 && mx.exchanger == 'mail.example.com.'
      }.should_not be_nil

      mx_records.detect { |mx|
        mx.host == "example.com." && mx.priority == 20 && mx.exchange == 'mail2.example.com.'
      }.should_not be_nil

      mx_records.detect { |mx|
        mx.host == "example.com." && mx.priority == 50 && mx.domainname == 'mail3.example.com.' && mx.ttl == 86400
      }.should_not be_nil

      mx_records.detect { |mx|
        mx.host == "test.example.com." && mx.priority == 10 && mx.domainname == 'mail.example.com.' && mx.ttl == 3600
      }.should_not be_nil
    end

    it "should build the correct AAAA records" do
      zone = DNS::Zonefile.load(@zonefile)
      aaaa_records = zone.records_of DNS::Zonefile::AAAA
      aaaa_records.size.should be(3)

      aaaa_records.detect { |a|
        a.host == "example.com." && a.address == "2001:db8:a::1"
      }.should_not be_nil

      aaaa_records.detect { |a|
        a.host == "ns.example.com." && a.address == "2001:db8:b::1"
      }.should_not be_nil

      aaaa_records.detect { |a|
        a.host == "mail.example.com." && a.address == "2001:db8:c::10.0.0.4" && a.ttl == 86400
      }.should_not be_nil
    end

    it "should build the correct NAPTR records" do
      zone = DNS::Zonefile.load(@zonefile)
      naptr_records = zone.records_of DNS::Zonefile::NAPTR
      naptr_records.size.should be(2)

      naptr_records.detect { |r|
        r.host == "sip.example.com." && r.data == '100 10 "U" "E2U+sip" "!^.*$!sip:cs@example.com!i" .'
      }.should_not be_nil

      naptr_records.detect { |r|
        r.host == "sip2.example.com." && r.data == %q{100 10 "" "" "/urn:cid:.+@([^\\.]+\\.)(.*)$/\\2/i" .} && r.ttl == 86400
      }.should_not be_nil
    end

    it "should build the correct SRV records" do
      zone = DNS::Zonefile.load(@zonefile)
      srv_records = zone.records_of DNS::Zonefile::SRV
      srv_records.size.should be(1)

      srv_records.detect { |r|
        r.host == "_xmpp-server._tcp.example.com." && r.priority == 5 && r.weight == 0 && r.port == 5269 && r.target == 'xmpp-server.l.google.com.' && r.ttl == 86400
      }.should_not be_nil
    end

    it "should build the correct TXT records" do
      zone = DNS::Zonefile.load(@zonefile)
      txt_records = zone.records_of DNS::Zonefile::TXT
      txt_records.size.should be(4)

      txt_records.detect { |r|
        r.host == "_domainkey.example.com." && r.data == '"v=DKIM1\;g=*\;k=rsa\; p=4tkw1bbkfa0ahfjgnbewr2ttkvahvfmfizowl9s4g0h28io76ndow25snl9iumpcv0jwxr2k"'
      }.should_not be_nil

      txt_records.detect { |r|
        r.host == "example.com." && r.data == '"some other \"message\" goes here"' && r.ttl == 86400
      }.should_not be_nil

      txt_records.detect { |r|
        r.host == "long.example.com." && r.data == '"a multi-segment TXT record" "usually used for really long TXT records" "since each segment can only span 255 chars"'
      }.should_not be_nil

      txt_records.detect { |r|
        r.host == "unquoted.example.com." && r.data == 'some text data'
      }.should_not be_nil
    end

    it "should build the correct SPF records" do
      zone = DNS::Zonefile.load(@zonefile)
      spf_records = zone.records_of DNS::Zonefile::SPF
      spf_records.size.should be(1)

      spf_records.detect { |r|
        r.host == "example.com." && r.data == '"v=spf1 a a:other.domain.com ~all"' && r.ttl == 86400
      }.should_not be_nil
    end

    it "should build the correct PTR records" do
      zone = DNS::Zonefile.load(@zonefile)
      ptr_records = zone.records_of DNS::Zonefile::PTR 
      ptr_records.size.should be(1)

      ptr_records.detect { |r|
        r.host == "45.example.com." && r.target == 'example.com.' && r.ttl == 86400
      }.should_not be_nil
    end
  end

  describe "parsing an SOA without parens" do
    before(:each) do
      @zonefile =<<-ZONE
example.com.	86400	IN	SOA	ns0.example.com. hostmaster.example.com. 2006010558 43200 3600 1209600 180
example.com.    3600    IN      A       1.2.3.4
example.com.	86400	IN	SOA	ns0.example.com. hostmaster.example.com. 2006010558 43200 3600 1209600 180

ZONE
    end

    it "should parse the SOA record correctly" do
      zone = DNS::Zonefile.load(@zonefile)
      soa = zone.soa
      soa.klass.should eql('IN')
      soa.ttl.should eql(86400)
      soa.nameserver.should eql('ns0.example.com.')
      soa.responsible_party.should eql('hostmaster.example.com.')
      soa.serial.should eql(2006010558)
      soa.refresh_time.should eql(43200)
      soa.retry_time.should eql(3600)
      soa.expiry_time.should eql(1209600)
      soa.nxttl.should eql(180)
    end
  end
end
