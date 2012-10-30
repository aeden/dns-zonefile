# DNS::Zonefile

The format of a DNS Zonefile is defined in RFC 1035 section 5 and RFC
1034 section 3.6.1. To anyone who's using BIND they'll look very
familiar.

This is an attempt to use Ruby parse them into an object graph which can
be investigated programatically, manipulated, validated or printed into
some canonical form.


## Getting setup

Well, you'll need the treetop and polyglot gems installed. They do all
the hard work. Thanks!

    sudo gem install treetop polyglot

Now you'll need to generate the Treetop parser from the Zonefile grammar
that I've hacked together.

    rake generate_grammar

Okay, you're ready to move onto the examples now.

The above steps should not be necessary if you install the gem via rubygems.


## Examples

Using raw data from the parser. Note that "@" isn't translated in this mode.
Nor are inherited TTLs interpreted.

    zonefile = "/path/to/file.zone"
    zone_string = File.read(zonefile)
    zone = DNS::Zonefile.parse(zone_string)

    puts zone.soa.origin.to_s
    puts zone.soa.ns.to_s
    puts zone.rr[0].to_s

Using more structure data. @, TTLs, and empty hostname inheritance are all
handled in this mode.

    zonefile = "/path/to/file.zone"
    zone_string = File.read(zonefile)
    zone = DNS::Zonefile.load(zone_string)
    # or, if no $origin is in the zone file
    zone = DNS::Zonefile.load(zone_string, 'example.com.')

    puts zone.soa.origin
    puts zone.soa.nameserver
    puts zone.records[1]
    # get all MX records
    puts zone.records_of(DNS::Zonefile::MX)


## Authors

Original code and concept:
Craig R Webster <http://barkingiguana.com/>

Additions:
t.e.morgan <http://zerigo.com/>


## Contributing

See the TODO. Send me patches or pull request either by email or on
GitHub.

[![Build Status](https://secure.travis-ci.org/craigw/dns-zonefile.png)](http://travis-ci.org/craigw/dns-zonefile)
