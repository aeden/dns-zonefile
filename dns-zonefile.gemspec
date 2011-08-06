$:.unshift File.dirname(__FILE__) + '/lib'
require 'dns/zonefile_version'

spec = Gem::Specification.new do |s|
  s.name = 'dns-zonefile'
  s.version = DNS::Zonefile::VERSION
  s.summary = "Parse and manipulate with DNS zonefiles."
  s.description = %{Parse and manipulate with DNS zonefiles. Great for working with BIND.}
  s.files = Dir['lib/**/*.rb'] + Dir['spec/**/*.rb']
  s.require_path = 'lib'
  s.autorequire = 'dns/zonefile'
  s.has_rdoc = true
  s.extra_rdoc_files = Dir['[A-Z]*'] + Dir['doc/**/*']
  s.rdoc_options << '--title' <<  'DNS::Zonefile -- Work with zonefiles'
  s.author = "Craig R Webster"
  s.email = "craig@barkingiguana.com"
  s.homepage = "http://barkingiguana.com/"
end
