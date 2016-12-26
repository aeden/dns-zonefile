# First make sure you have installed the `dns-zonefile` gem.
# 
# Run this script with `ruby basic.rb`

require 'dns/zonefile'

zonefile = "example.com.zonefile"
zone_string = File.read(zonefile)
zone = DNS::Zonefile.parse(zone_string)

puts zone.soa.origin.to_s
puts zone.soa.ns.to_s
puts zone.rr[0].to_s
