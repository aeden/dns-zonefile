# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dns/zonefile/version"

Gem::Specification.new do |s|
  s.name        = "dns-zonefile"
  s.version     = DNS::Zonefile::VERSION
  s.authors     = ["Craig R Webster"]
  s.email       = ["craig@barkingiguana.com"]
  s.homepage    = ""
  s.summary     = %q{Work with zonefiles (RFC 1035 section 5 and RFC 1034 section 3.6.1)}
  s.description = %q{The format of a DNS Zonefile is defined in RFC 1035 section 5 and RFC
1034 section 3.6.1. To anyone who's using BIND they'll look very 
familiar.

This is an attempt to use Ruby parse them into an object graph which can 
be investigated programatically, manipulated, validated or printed into 
some canonical form.}

  s.rubyforge_project = "dns-zonefile"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", "= 2.6"
  s.add_development_dependency "rake"
  s.add_runtime_dependency "treetop"
  s.add_runtime_dependency "polyglot"
end
