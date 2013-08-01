# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'travis_bundle_cache/version'

Gem::Specification.new do |spec|
  spec.name          = "travis_bundle_cache"
  spec.version       = TravisBundleCache::VERSION
  spec.authors       = ["David Genord II"]
  spec.email         = ["david@collectiveidea.com"]
  spec.description   = %q{Cache the gem bundle for speedy travis builds}
  spec.summary       = %q{Cache the gem bundle for speedy travis builds}
  spec.homepage      = "https://github.com/collectiveidea/travis_bundle_cache"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.executables   = ["travis_bundle_cache", "travis_bundle_install"]

  spec.add_dependency "bundler", "~> 1.3"
  spec.add_dependency "fog"
end
