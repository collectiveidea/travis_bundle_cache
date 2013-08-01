# TravisBundleCache

[![Gem Version](https://badge.fury.io/rb/travis_bundle_cache.png)](http://badge.fury.io/rb/travis_bundle_cache)

Cache the gem bundle for speedy travis builds

## Usage

1. Set up a bucket on S3 in the US Standard region (us-east-1) (and possibly a new user via IAM)
2. Install the travis gem with gem install travis
3. Log into Travis with travis login --auto (from inside your project respository directory)
4. Encrypt your S3 credentials with: travis encrypt AWS_S3_KEY="" AWS_S3_SECRET="" --add (be sure to add your actual credentials inside the double quotes)
5. Setup your .travis.yml to include the following

```yaml
env:
  global:
    - BUNDLE_ARCHIVE="your-bundle-name"
    - AWS_S3_REGION="us-east-1"
    - AWS_S3_BUCKET="your-bucket-name"

before_install:
  - "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
  - "gem install travis_bundle_cache"

install: travis_bundle_install

after_script:
  - "travis_bundle_cache"
```

Enjoy faster builds

## Contributions

TravisBundleCache is open source and contributions from the community are encouraged! No contribution is too small. Please consider:

* adding an awesome feature
* fixing a terrible bug
* updating documentation
* fixing a not-so-bad bug
* fixing typos

For the best chance of having your changes merged, please:

1. Ask us! We'd love to hear what you're up to.
2. Fork the project.
3. Commit your changes and tests (if applicable (they're applicable)).
4. Submit a pull request with a thorough explanation and at least one animated GIF.

## Thanks

Most of the credit for this gem goes to Random Errata and [this](http://randomerrata.com/post/45827813818/travis-s3) blog post