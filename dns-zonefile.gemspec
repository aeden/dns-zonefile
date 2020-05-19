# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dns/zonefile/version'

Gem::Specification.new do |spec|
  spec.name          = "dns-zonefile"
  spec.version       = DNS::Zonefile::VERSION
  spec.authors       = ["Craig R Webster", "Anthony Eden"]
  spec.email         = ["craig@barkingiguana.com", "anthonyeden@gmail.com"]

  spec.summary     = %q{Work with zonefiles (RFC 1035 section 5 and RFC 1034 section 3.6.1)}
  spec.description = <<-EOD
The format of a DNS Zonefile is defined in RFC 1035 section 5 and RFC
1034 section 3.6.1. To anyone who's using BIND they'll look very
familiar.

This is an attempt to use Ruby parse them into an object graph which can
be investigated programatically, manipulated, validated or printed into
some canonical form.
  EOD
  spec.homepage      = "https://github.com/craigw/dns-zonefile"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "treetop", '~> 1.6'
  spec.add_dependency "polyglot", '~> 0.3'
  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
