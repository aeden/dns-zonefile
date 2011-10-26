# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dns/zonefile/version"

Gem::Specification.new do |s|
  s.name        = "dns-zonefile"
  s.version     = DNS::Zonefile::VERSION
  s.authors     = ["Craig R Webster"]
  s.email       = ["craig@barkingiguana.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "dns-zonefile"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", "= 2.6"
  s.add_development_dependency "treetop"
  s.add_runtime_dependency "polyglot"
end
