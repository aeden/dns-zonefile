require 'rubygems'
require 'polyglot'
require 'treetop'
require 'zonefile'

zonefile = %Q(
; Hi! I'm an example zonefile.
example.com.  IN  SOA  ns.example.com. username.example.com. ( 
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
)

parser = ZonefileParser.new
zone = parser.parse(zonefile)
if zone
  p zone
else
  puts "Could not parse zonefile"
end