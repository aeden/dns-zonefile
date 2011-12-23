require 'spec_helper'
require 'dns/zonefile'

describe "DNS::Zonefile" do
  it "should be versioned" do
    lambda {
      DNS::Zonefile.const_get(:VERSION)
    }.should_not raise_error
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
@             IN  SOA  ns.example.com. hostmaster\\.awesome.example.com. (
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

    it "work damnit" do
l = %q(alphagov.co.uk. 300 IN SOA ns1.p08.dynect.net. james\.stewart.digital.cabinet-office.gov.uk. ( 63 3600 600 604800 300 )
preview-mongo_server-client-20111212134837-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.129.154
test-centres.production.alphagov.co.uk. 300 IN A 127.0.0.1
monitoring.production.alphagov.co.uk. 300 IN A 46.51.143.167
government.production.alphagov.co.uk. 300 IN A 127.0.0.1
decide.production.alphagov.co.uk. 300 IN A 127.0.0.1
article.production.alphagov.co.uk. 300 IN A 127.0.0.1
production-frontend.alphagov.co.uk. 300 IN A 79.125.19.241
production-cache.alphagov.co.uk. 300 IN A 176.34.196.237
production-backend.alphagov.co.uk. 300 IN A 46.137.92.153
preview-frontend.alphagov.co.uk. 300 IN A 46.51.151.203
preview-cache.alphagov.co.uk. 300 IN A 176.34.205.133
preview-backend.alphagov.co.uk. 300 IN A 46.137.19.107
mapit.alphagov.co.uk. 300 IN A 79.125.16.53
management.alphagov.co.uk. 300 IN A 79.125.30.178
production-mongo-client-20111213170556-01-internal.hosts.alphagov.co.uk. 300 IN A 10.58.177.40
production-mongo-client-20111213170556-01-external.hosts.alphagov.co.uk. 300 IN A 46.51.133.36
production-mongo-client-20111213170552-01-internal.hosts.alphagov.co.uk. 300 IN A 10.49.6.84
production-mongo-client-20111213170552-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.29.48
production-mongo-client-20111213170334-01-internal.hosts.alphagov.co.uk. 300 IN A 10.228.247.32
production-mongo-client-20111213170334-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.19.162
production-mongo-client-20111213163912-01-internal.hosts.alphagov.co.uk. 300 IN A 10.235.97.73
production-mongo-client-20111213163912-01-external.hosts.alphagov.co.uk. 300 IN A 176.34.201.254
production-mongo-client-20111213161117-01-internal.hosts.alphagov.co.uk. 300 IN A 10.58.238.123
production-mongo-client-20111213161117-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.152.33
production-mongo-client-20111213161112-01-internal.hosts.alphagov.co.uk. 300 IN A 10.236.255.109
production-mongo-client-20111213161112-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.154.147
production-mongo-client-20111213161101-01-internal.hosts.alphagov.co.uk. 300 IN A 10.50.41.99
production-mongo-client-20111213161101-01-external.hosts.alphagov.co.uk. 300 IN A 79.125.44.174
preview-mongo_server-client-20111212140009-01-internal.hosts.alphagov.co.uk. 300 IN A 10.55.82.139
preview-mongo_server-client-20111212140009-01-external.hosts.alphagov.co.uk. 300 IN A 46.51.136.160
preview-mongo_server-client-20111212135456-01-internal.hosts.alphagov.co.uk. 300 IN A 10.228.243.175
preview-mongo_server-client-20111212135456-01-external.hosts.alphagov.co.uk. 300 IN A 176.34.196.65
preview-mongo_server-client-20111212135012-01-internal.hosts.alphagov.co.uk. 300 IN A 10.50.39.252
preview-mongo_server-client-20111212135012-01-external.hosts.alphagov.co.uk. 300 IN A 176.34.202.19
preview-mongo_server-client-20111212134837-01-internal.hosts.alphagov.co.uk. 300 IN A 10.234.67.228
transactions.production.alphagov.co.uk. 300 IN A 127.0.0.1
preview-mongo-client-20111213160744-01-internal.hosts.alphagov.co.uk. 300 IN A 10.234.166.88
preview-mongo-client-20111213160744-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.47.149
preview-mongo-client-20111213143425-01-internal.hosts.alphagov.co.uk. 300 IN A 10.250.162.90
preview-mongo-client-20111213143425-01-external.hosts.alphagov.co.uk. 300 IN A 176.34.204.251
preview-mongo-client-20111213125804-01-internal.hosts.alphagov.co.uk. 300 IN A 10.238.130.79
preview-mongo-client-20111213125804-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.129.231
preview-mongo-client-20111213124811-01-internal.hosts.alphagov.co.uk. 300 IN A 10.50.39.163
preview-mongo-client-20111213124811-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.43.11
preview-mongo-client-20111213123744-01-internal.hosts.alphagov.co.uk. 300 IN A 10.250.177.151
preview-mongo-client-20111213123744-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.47.68
preview-mongo-client-20111213123553-01-internal.hosts.alphagov.co.uk. 300 IN A 10.58.127.24
preview-mongo-client-20111213123553-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.128.122
preview-data-internal.hosts.alphagov.co.uk. 300 IN A 10.59.61.129
preview-backend-client-lwg6tb-01-internal.hosts.alphagov.co.uk. 300 IN A 10.228.95.176
preview-backend-client-lwg6tb-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.19.107
preview-backend-client-lwg6c3-01-internal.hosts.alphagov.co.uk. 300 IN A 10.235.65.125
preview-backend-client-lwg6c3-01-external.hosts.alphagov.co.uk. 300 IN A 176.34.212.217
dghtest-puppet-master-20111212112510-01-internal.hosts.alphagov.co.uk. 300 IN A 10.235.87.253
dghtest-puppet-master-20111212112510-01-external.hosts.alphagov.co.uk. 300 IN A 46.137.12.190
dghtest-puppet-master-20111212103659-01-internal.alphagov.co.uk. 300 IN A 10.234.221.104
dghtest-puppet-master-20111212103659-01-external.alphagov.co.uk. 300 IN A 46.137.7.11
dghtest-puppet-master-20111212103523-01-internal.alphagov.co.uk. 300 IN A 10.224.57.120
dghtest-puppet-master-20111212103523-01-external.alphagov.co.uk. 300 IN A 46.137.21.166
dghtest-puppet-master-20111212103151-01-internal.alphagov.co.uk. 300 IN A 10.224.114.51
dghtest-puppet-master-20111212103151-01-external.alphagov.co.uk. 300 IN A 176.34.203.166
dghtest-puppet-master-20111212101727-01-internal.alphagov.co.uk. 300 IN A 10.234.111.117
dghtest-puppet-master-20111212101727-01-external.alphagov.co.uk. 300 IN A 79.125.62.198
dev.alphagov.co.uk. 300 IN A 46.137.92.153
blog.alphagov.co.uk. 300 IN A 46.137.92.159
alfred.alphagov.co.uk. 300 IN A 172.16.128.19
alphagov.co.uk. 60 IN A 172.16.128.19
alphagov.co.uk. 300 IN TXT google-site-verification=59E-U5aNbpb1Lx5YgF2191zNLQtyndRfd9SS7_-zRjs
alphagov.co.uk. 300 IN TXT google-site-verification=3lWawlyOEUtLQp08TG6bj11uFX3i3F7dj8apq71Wumk
alphagov.co.uk. 86400 IN NS ns4.p08.dynect.net.
alphagov.co.uk. 86400 IN NS ns3.p08.dynect.net.
alphagov.co.uk. 86400 IN NS ns2.p08.dynect.net.
alphagov.co.uk. 86400 IN NS ns1.p08.dynect.net.
alphagov.co.uk. 300 IN MX 30 aspmx5.googlemail.com.
alphagov.co.uk. 300 IN MX 30 aspmx4.googlemail.com.
alphagov.co.uk. 300 IN MX 30 aspmx3.googlemail.com.
alphagov.co.uk. 300 IN MX 30 aspmx2.googlemail.com.
alphagov.co.uk. 300 IN MX 30 alt2.aspmx.l.google.com.
alphagov.co.uk. 300 IN MX 20 alt1.aspmx.l.google.com.
alphagov.co.uk. 300 IN MX 10 aspmx.l.google.com.
www2.production.alphagov.co.uk. 300 IN A 176.34.192.178
tiles.alphagov.co.uk. 300 IN CNAME tiles.alphagov.co.uk.s3.amazonaws.com.
whitehall.staging.alphagov.co.uk. 300 IN CNAME ec2-46-137-37-127.eu-west-1.compute.amazonaws.com.
assets1.staging.alphagov.co.uk. 300 IN CNAME d25droa7ql04sg.cloudfront.net.
assets0.staging.alphagov.co.uk. 300 IN CNAME d25droa7ql04sg.cloudfront.net.
*.staging.alphagov.co.uk. 300 IN CNAME staging.alphagov.co.uk.
staging.alphagov.co.uk. 300 IN CNAME ec2-46-51-135-250.eu-west-1.compute.amazonaws.com.
www3.production.alphagov.co.uk. 300 IN CNAME govuk-513134630.eu-west-1.elb.amazonaws.com.
www-elb.production.alphagov.co.uk. 300 IN CNAME production-1934955571.eu-west-1.elb.amazonaws.com.
www.production.alphagov.co.uk. 300 IN CNAME production-cache.alphagov.co.uk.
whitehall-search.production.alphagov.co.uk. 300 IN CNAME whitehall.production.alphagov.co.uk.
whitehall.production.alphagov.co.uk. 300 IN CNAME ec2-46-137-147-10.eu-west-1.compute.amazonaws.com.
static.production.alphagov.co.uk. 300 IN CNAME production-frontend.alphagov.co.uk.
smartanswers.production.alphagov.co.uk. 300 IN CNAME production-frontend.alphagov.co.uk.
signonotron.production.alphagov.co.uk. 300 IN CNAME production-backend.alphagov.co.uk.
search.production.alphagov.co.uk. 300 IN CNAME production-frontend.alphagov.co.uk.
publisher.production.alphagov.co.uk. 300 IN CNAME production-backend.alphagov.co.uk.
private-frontend.production.alphagov.co.uk. 300 IN CNAME production-backend.alphagov.co.uk.
planner.production.alphagov.co.uk. 300 IN CNAME production-frontend.alphagov.co.uk.
panopticon.production.alphagov.co.uk. 300 IN CNAME production-backend.alphagov.co.uk.
needotron.production.alphagov.co.uk. 300 IN CNAME production-backend.alphagov.co.uk.
jobs.production.alphagov.co.uk. 300 IN CNAME production-frontend.alphagov.co.uk.
imminence.production.alphagov.co.uk. 300 IN CNAME production-backend.alphagov.co.uk.
frontend.production.alphagov.co.uk. 300 IN CNAME production-frontend.alphagov.co.uk.
fco.production.alphagov.co.uk. 300 IN CNAME production-frontend.alphagov.co.uk.
contactotron.production.alphagov.co.uk. 300 IN CNAME production-backend.alphagov.co.uk.
calendars.production.alphagov.co.uk. 300 IN CNAME production-frontend.alphagov.co.uk.
assets1.production.alphagov.co.uk. 300 IN CNAME d3bu97gfkl47od.cloudfront.net.
assets0.production.alphagov.co.uk. 300 IN CNAME d3bu97gfkl47od.cloudfront.net.
production.alphagov.co.uk. 300 IN CNAME alphagov-production-845813760.eu-west-1.elb.amazonaws.com.
www-router.preview.alphagov.co.uk. 300 IN CNAME preview-cache.alphagov.co.uk.
www-elb.preview.alphagov.co.uk. 300 IN CNAME preview-194011342.eu-west-1.elb.amazonaws.com.
www-cache.preview.alphagov.co.uk. 300 IN CNAME preview-cache.alphagov.co.uk.
www.preview.alphagov.co.uk. 300 IN CNAME preview-194011342.eu-west-1.elb.amazonaws.com.
whitehall-search.preview.alphagov.co.uk. 300 IN CNAME whitehall.preview.alphagov.co.uk.
whitehall.preview.alphagov.co.uk. 300 IN CNAME ec2-46-137-37-127.eu-west-1.compute.amazonaws.com.
static.preview.alphagov.co.uk. 300 IN CNAME preview-frontend.alphagov.co.uk.
smartanswers.preview.alphagov.co.uk. 300 IN CNAME preview-frontend.alphagov.co.uk.
signonotron.preview.alphagov.co.uk. 300 IN CNAME preview-backend.alphagov.co.uk.
search.preview.alphagov.co.uk. 300 IN CNAME preview-frontend.alphagov.co.uk.
publisher.preview.alphagov.co.uk. 300 IN CNAME preview-backend.alphagov.co.uk.
private-frontend.preview.alphagov.co.uk. 300 IN CNAME preview-backend.alphagov.co.uk.
planner.preview.alphagov.co.uk. 300 IN CNAME preview-frontend.alphagov.co.uk.
panopticon.preview.alphagov.co.uk. 300 IN CNAME preview-backend.alphagov.co.uk.
needotron.preview.alphagov.co.uk. 300 IN CNAME preview-backend.alphagov.co.uk.
jobs.preview.alphagov.co.uk. 300 IN CNAME preview-frontend.alphagov.co.uk.
imminence.preview.alphagov.co.uk. 300 IN CNAME preview-backend.alphagov.co.uk.
frontend.preview.alphagov.co.uk. 300 IN CNAME preview-frontend.alphagov.co.uk.
fco.preview.alphagov.co.uk. 300 IN CNAME preview-frontend.alphagov.co.uk.
contactotron.preview.alphagov.co.uk. 300 IN CNAME preview-backend.alphagov.co.uk.
calendars.preview.alphagov.co.uk. 300 IN CNAME preview-frontend.alphagov.co.uk.
mail.alphagov.co.uk. 300 IN CNAME ghs.google.com.
production-rds-lw96xc-01-internal.hosts.alphagov.co.uk. 300 IN CNAME production-rds-lw96xc-01.coyxzkuy9kq4.eu-west-1.rds.amazonaws.com.
preview-rds-lw7dsu-01-internal.hosts.alphagov.co.uk. 300 IN CNAME preview-rds-lw7dsu-01.coyxzkuy9kq4.eu-west-1.rds.amazonaws.com.
preview-rds-lw7cfo-01-internal.hosts.alphagov.co.uk. 300 IN CNAME preview-rds-lw7cfo-01.coyxzkuy9kq4.eu-west-1.rds.amazonaws.com.
preview-rds-lw7aej-01-internal.hosts.alphagov.co.uk. 300 IN CNAME preview-rds-lw7aej-01.coyxzkuy9kq4.eu-west-1.rds.amazonaws.com.
preview-rds-lw6zso-01-internal.hosts.alphagov.co.uk. 300 IN CNAME preview-rds-lw6zso-01.coyxzkuy9kq4.eu-west-1.rds.amazonaws.com.
fallback.alphagov.co.uk. 300 IN CNAME ag-static-1.s3-website-eu-west-1.amazonaws.com.
docs.alphagov.co.uk. 300 IN CNAME ghs.google.com.
assets1.dev.alphagov.co.uk. 300 IN CNAME d26d1oopru8z8c.cloudfront.net.
assets0.dev.alphagov.co.uk. 300 IN CNAME d26d1oopru8z8c.cloudfront.net.
*.dev.alphagov.co.uk. 300 IN CNAME dev.alphagov.co.uk.
demo.alphagov.co.uk. 300 IN CNAME staging.alphagov.co.uk.
ci.alphagov.co.uk. 300 IN CNAME management.alphagov.co.uk.
calendar.alphagov.co.uk. 300 IN CNAME ghs.google.com.
*.admin.alphagov.co.uk. 300 IN CNAME admin.alphagov.co.uk.
admin.alphagov.co.uk. 300 IN CNAME ec2-46-51-133-243.eu-west-1.compute.amazonaws.com.
)
DNS::Zonefile.parse(l)
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
      soa.responsible_party.should eql('hostmaster\.awesome.example.com.')
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
