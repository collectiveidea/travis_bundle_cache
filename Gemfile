source 'https://rubygems.org'

# Specify your gem's dependencies in travis_bundle_cache.gemspec
gemspec

gem 'rake'

group :test do
  gem "coveralls", "~> 0.6.7", require: false
  gem "rspec",     "~> 2.14"
  gem "fakefs",                require: "fakefs/safe"
end
