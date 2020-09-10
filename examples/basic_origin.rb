# First make sure you have installed the `dns-zonefile` gem.
#
# Run this script with `ruby basic.rb`

require "dns/zonefile"

zonefile = "example.com.zonefile"
zone = DNS::Zonefile.load(File.read(zonefile), "example.com.")

puts zone.soa.origin
puts zone.soa.nameserver
# get all MX records
zone.records_of(DNS::Zonefile::MX).each do |rec|
  puts "#{rec.host} #{rec.klass} #{rec.ttl} #{rec.priority} #{rec.domainname}"
end
