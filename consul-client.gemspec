# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'consul/client/version'

Gem::Specification.new do |spec|
  spec.name          = "consul-client"
  spec.version       = Consul::Client::VERSION
  spec.authors       = ["Michael Hotan"]
  spec.email         = ["michael.hotan@socrata.com"]
  spec.summary       = %q{Ruby Client library for communicating with Consul.}
  spec.description   = %q{Consul agents expose a HTTP REST API and this library is used to communicate directly with it.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_dependency 'rest-client', '~> 1.8'
  spec.add_dependency 'representable', '~> 2.1'
  spec.add_dependency 'json', '~> 1.8'
end
