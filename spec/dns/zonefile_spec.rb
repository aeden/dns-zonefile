require 'spec_helper'
require 'dns/zonefile'

RSpec.describe "DNS::Zonefile" do
  it "should be versioned" do
    expect { DNS::Zonefile.const_get(:VERSION) }.to_not raise_error
  end

  it "should provide a way of parsing a string" do
    expect(DNS::Zonefile).to respond_to(:parse)
  end

  describe "parsing a zonefile string" do
    before(:each) do
      @zonefile =<<-ZONE
; Hi! I'm an example zonefile.
$ORIGIN example.com.
$TTL 86400; expire in 1 day.
$OTHER abc
; line above has spaces at the end, but no comment
@             IN  SOA  ns.example.com. hostmaster\\.awesome.example.com. (
;
              2007120710 ; serial number of this zone file
              ;two
              ;comments
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
with_ms_txt   TXT   ( "Some text" )

@             TXT   "some other \\"message\\" goes here" ; embedded quotes
long          TXT   "a multi-segment TXT record" "usually used for really long TXT records" "since each segment can only span 255 chars"
unquoted      TXT   some text data

multiline     TXT   "A TXT record
split across multiple lines
with LF and CRLF line endings"

; Microsoft AD DNS Examples with Aging.
with-age [AGE:999992222] 60     A   10.0.0.7             ; with a specified AGE
with-age-aaaa [AGE:999992222] 60     AAAA   10.0.0.8             ; with a specified AGE
_ldap._tcp.pupy._sites.dc._msdcs [AGE:3636525]	600	SRV	0 100 389	host01.ad
P229392922               [AGE:3636449]	172800	CNAME	printer01.ad

@             SPF   "v=spf1 a a:other.domain.com ~all"

45        IN   PTR   @


eam 900 IN SRV 5 0 5269 www
eam IN 900 SRV 5 0 5269 www
eam IN SRV 5 0 5269 www
eam 900 SRV 5 0 5269 www
eam SRV 5 0 5269 www

eam 900 IN CNAME www
eam IN 900 CNAME www
eam IN CNAME www
eam 900 CNAME www
eam CNAME www

$ORIGIN test.example.com.
$TTL 3600; expire in 1 day.
@             A     10.1.0.1              ; Test with alternate origin
              MX    10  mail.example.com.
www           A     10.1.0.2              ; www.test.example.com.

ZONE
    end

    it "should set the origin correctly" do
      zone = DNS::Zonefile.parse(@zonefile)
      expect(zone.origin).to eq('@')
    end

    it "should interpret the origin correctly" do
      zone = DNS::Zonefile.load(@zonefile)
      expect(zone.soa.origin).to eq('example.com.')
    end

    it "should set the zone variables correctly" do
      zone = DNS::Zonefile.parse(@zonefile)
      expect(zone.variables['TTL']).to eq('86400')
      expect(zone.variables['ORIGIN']).to eq('example.com.')
    end

    it "should interpret the SOA correctly" do
      zone = DNS::Zonefile.load(@zonefile)
      soa = zone.soa
      expect(soa.klass).to eq('IN')
      expect(soa.ttl).to eq(86400)
      expect(soa.nameserver).to eq('ns.example.com.')
      expect(soa.responsible_party).to eq('hostmaster\.awesome.example.com.')
      expect(soa.serial).to eq(2007120710)
      expect(soa.refresh_time).to eq(86400)
      expect(soa.retry_time).to eq(86400)
      expect(soa.expiry_time).to eq(2419200)
      expect(soa.nxttl).to eq(3600)
    end

    it "should build the correct number of resource records" do
      zone = DNS::Zonefile.parse(@zonefile)
      expect(zone.rr.size).to eq(49)
    end

    it "should build the correct NS records" do
      zone = DNS::Zonefile.load(@zonefile)
      ns_records = zone.records_of DNS::Zonefile::NS
      expect(ns_records.size).to eq(2)

      expect(ns_records.detect { |ns|
        ns.host == "example.com." && ns.nameserver == "ns.example.com."
      }).to_not be_nil

      expect(ns_records.detect { |ns|
        ns.host == "example.com." && ns.nameserver == "ns.somewhere.com." && ns.ttl == 86400
      }).to_not be_nil
    end

    it "should build the correct A records" do
      zone = DNS::Zonefile.load(@zonefile)
      a_records = zone.records_of DNS::Zonefile::A
      expect(a_records.size).to eq(13)

      expect(a_records.detect { |a|
        a.host == "example.com." && a.address == "10.0.0.1"
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "example.com." && a.address == "10.0.0.11"
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "example.com." && a.address == "10.0.0.12"
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "ns.example.com." && a.address == "10.0.0.2" && a.ttl == 86400
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "ns.example.com." && a.address == "10.0.0.21" && a.ttl == 60
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "*.example.com." && a.address == "10.0.0.100"
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "*.sub.example.com." && a.address == "10.0.0.101"
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "with-class.example.com." && a.address == "10.0.0.3" && a.ttl == 86400
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "with-ttl.example.com." && a.address == "10.0.0.5" && a.ttl == 60
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "with-age.example.com." && a.address == "10.0.0.7" && a.ttl == 60
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "ttl-class.example.com." && a.address == "10.0.0.6" && a.ttl == 60
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "test.example.com." && a.address == "10.1.0.1" && a.ttl == 3600
      }).to_not be_nil

      expect(a_records.detect { |a|
        a.host == "www.test.example.com." && a.address == "10.1.0.2" && a.ttl == 3600
      }).to_not be_nil
    end

    it "should build the correct CNAME records" do
      zone = DNS::Zonefile.load(@zonefile)
      cname_records = zone.records_of DNS::Zonefile::CNAME
      expect(cname_records.size).to eq(9)

      expect(cname_records.detect { |cname|
        cname.host == "www.example.com." && cname.target == "ns.example.com."
      }).to_not be_nil

      expect(cname_records.detect { |cname|
        cname.host == "wwwtest.example.com." && cname.domainname == "www.example.com."
      }).to_not be_nil

      expect(cname_records.detect { |cname|
        cname.host == "www2.example.com." && cname.domainname == "ns.example.com." && cname.ttl == 86400
      }).to_not be_nil

      expect(cname_records.detect { |cname|
        cname.host == "P229392922.example.com." && cname.domainname == "printer01.ad.example.com." && cname.ttl == 172800
      }).to_not be_nil

     eam_records = cname_records.select { |c| c.host =~ /eam\./ }

     expect(eam_records.length).to eq(5)

     eam_records.each { |cname|
       expect(cname.target).to eq("www.example.com.")
     }

     r = eam_records.group_by { |c| c.ttl }
     expect(r[900].length).to eq(3)
     expect(r[86400].length).to eq(2)
    end

    it "should build the correct MX records" do
      zone = DNS::Zonefile.load(@zonefile)
      mx_records = zone.records_of DNS::Zonefile::MX
      expect(mx_records.length).to eq(4)

      expect(mx_records.detect { |mx|
        mx.host == "example.com." && mx.priority == 10 && mx.exchanger == 'mail.example.com.'
      }).to_not be_nil

      expect(mx_records.detect { |mx|
        mx.host == "example.com." && mx.priority == 20 && mx.exchange == 'mail2.example.com.'
      }).to_not be_nil

      expect(mx_records.detect { |mx|
        mx.host == "example.com." && mx.priority == 50 && mx.domainname == 'mail3.example.com.' && mx.ttl == 86400
      }).to_not be_nil

      expect(mx_records.detect { |mx|
        mx.host == "test.example.com." && mx.priority == 10 && mx.domainname == 'mail.example.com.' && mx.ttl == 3600
      }).to_not be_nil
    end

    it "should build the correct AAAA records" do
      zone = DNS::Zonefile.load(@zonefile)
      aaaa_records = zone.records_of DNS::Zonefile::AAAA
      expect(aaaa_records.length).to eq(4)

      expect(aaaa_records.detect { |a|
        a.host == "example.com." && a.address == "2001:db8:a::1"
      }).to_not be_nil

      expect(aaaa_records.detect { |a|
        a.host == "ns.example.com." && a.address == "2001:db8:b::1"
      }).to_not be_nil

      expect(aaaa_records.detect { |a|
        a.host == "mail.example.com." && a.address == "2001:db8:c::10.0.0.4" && a.ttl == 86400
      }).to_not be_nil

      expect(aaaa_records.detect { |a|
        a.host == "with-age-aaaa.example.com." && a.address == "10.0.0.8" && a.ttl == 60
      }).to_not be_nil

    end

    it "should build the correct NAPTR records" do
      zone = DNS::Zonefile.load(@zonefile)
      naptr_records = zone.records_of DNS::Zonefile::NAPTR
      expect(naptr_records.length).to eq(2)

      expect(naptr_records.detect { |r|
        r.host == "sip.example.com." && r.data == '100 10 "U" "E2U+sip" "!^.*$!sip:cs@example.com!i" .'
      }).to_not be_nil

      expect(naptr_records.detect { |r|
        r.host == "sip2.example.com." && r.data == %q{100 10 "" "" "/urn:cid:.+@([^\\.]+\\.)(.*)$/\\2/i" .} && r.ttl == 86400
      }).to_not be_nil
    end

    it "should build the correct SRV records" do
      zone = DNS::Zonefile.load(@zonefile)
      srv_records = zone.records_of DNS::Zonefile::SRV
      expect(srv_records.length).to eq(7)

      expect(srv_records.detect { |r|
        r.host == "_xmpp-server._tcp.example.com." && r.priority == 5 && r.weight == 0 && r.port == 5269 && r.target == 'xmpp-server.l.google.com.' && r.ttl == 86400
      }).to_not be_nil

      expect(srv_records.detect { |r|
        r.host == "_ldap._tcp.pupy._sites.dc._msdcs.example.com." && r.priority == 0 && r.weight == 100 && r.port == 389 && r.target == 'host01.ad.example.com.' && r.ttl == 600
      }).to_not be_nil

      eam_records = srv_records.select { |s| s.host =~ /eam\./ }
      expect(eam_records.length).to eq(5)
      eam_records.each { |srv|
        expect(srv.target).to eq("www.example.com.")
        expect(srv.priority).to eq(5)
        expect(srv.port).to eq(5269)
        expect(srv.weight).to eq(0)
      }

      r = eam_records.group_by { |c| c.ttl }
      expect(r[900].length).to eq(3)
      expect(r[86400].length).to eq(2)
    end

    it "should build the correct TXT records" do
      zone = DNS::Zonefile.load(@zonefile)
      txt_records = zone.records_of DNS::Zonefile::TXT
      expect(txt_records.size).to eq(6)

      expect(txt_records.detect { |r|
        r.host == "_domainkey.example.com." && r.data == '"v=DKIM1\;g=*\;k=rsa\; p=4tkw1bbkfa0ahfjgnbewr2ttkvahvfmfizowl9s4g0h28io76ndow25snl9iumpcv0jwxr2k"'
      }).to_not be_nil

      expect(txt_records.detect { |r|
        r.host == "with_ms_txt.example.com." && r.data == '"Some text"'
      }).to_not be_nil

      expect(txt_records.detect { |r|
        r.host == "example.com." && r.data == '"some other \"message\" goes here"' && r.ttl == 86400
      }).to_not be_nil

      expect(txt_records.detect { |r|
        r.host == "long.example.com." && r.data == '"a multi-segment TXT record" "usually used for really long TXT records" "since each segment can only span 255 chars"'
      }).to_not be_nil

      expect(txt_records.detect { |r|
        r.host == "unquoted.example.com." && r.data == 'some text data'
      }).to_not be_nil

      expect(txt_records.detect { |r|
        r.host == "multiline.example.com." && r.data == "\"A TXT record\nsplit across multiple lines\nwith LF and CRLF line endings\""
      }).to_not be_nil
    end

    it "should build the correct SPF records" do
      zone = DNS::Zonefile.load(@zonefile)
      spf_records = zone.records_of DNS::Zonefile::SPF
      expect(spf_records.length).to eq(1)

      expect(spf_records.detect { |r|
        r.host == "example.com." && r.data == '"v=spf1 a a:other.domain.com ~all"' && r.ttl == 86400
      }).to_not be_nil
    end

    it "should build the correct PTR records" do
      zone = DNS::Zonefile.load(@zonefile)
      ptr_records = zone.records_of DNS::Zonefile::PTR
      expect(ptr_records.length).to eq(1)

      expect(ptr_records.detect { |r|
        r.host == "45.example.com." && r.target == 'example.com.' && r.ttl == 86400
      }).to_not be_nil
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
      expect(soa.klass).to eql('IN')
      expect(soa.ttl).to eql(86400)
      expect(soa.nameserver).to eql('ns0.example.com.')
      expect(soa.responsible_party).to eql('hostmaster.example.com.')
      expect(soa.serial).to eql(2006010558)
      expect(soa.refresh_time).to eql(43200)
      expect(soa.retry_time).to eql(3600)
      expect(soa.expiry_time).to eql(1209600)
      expect(soa.nxttl).to eql(180)
    end
  end

  describe "parsing an SOA with just . for responsible party" do
    before(:each) do
      @zonefile =<<-ZONE
@             IN  SOA  ns.domain.example.com. . (
              2007120710 ; serial number of this zone file
              1d         ; slave refresh (1 day)
              1d         ; slave retry time in case of a problem (1 day)
              4W         ; slave expiration time (4 weeks)
              3600       ; minimum caching time in case of failed lookups (1 hour)
              )
ZONE
    end

    it "should parse the SOA record correctly" do
      zone = DNS::Zonefile.load(@zonefile)
      soa = zone.soa
      expect(soa.klass).to eql('IN')
      expect(soa.nameserver).to eql('ns.domain.example.com.')
      expect(soa.responsible_party).to eql('.')
    end
  end
end
