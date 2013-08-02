require "coveralls"
Coveralls.wear!

require "travis_bundle_cache"

require "fakefs/spec_helpers"

RSpec.configure do |config|
  config.order = "random"
  config.expect_with(:rspec) {|c| c.syntax = :expect }
  config.include FakeFS::SpecHelpers
end
