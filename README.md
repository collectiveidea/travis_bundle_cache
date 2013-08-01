Travis Bundle Cache
===================
[![Gem Version](https://badge.fury.io/rb/travis_bundle_cache.png)](http://badge.fury.io/rb/travis_bundle_cache)
[![Code Climate](https://codeclimate.com/github/collectiveidea/travis_bundle_cache.png)](https://codeclimate.com/github/collectiveidea/travis_bundle_cache)
[![Dependency Status](https://gemnasium.com/collectiveidea/travis_bundle_cache.png)](https://gemnasium.com/collectiveidea/travis_bundle_cache)

The primary purpose of this gem is to make [this](http://randomerrata.com/post/45827813818/travis-s3) easier and slightly more maintainable.

This gem loads, builds, and saves a cache of your bundled gems on S3 by *ONLY* modifying your project's .travis.yml file.

What you will need:
* A project on Travis CI
* An AWS account
* A "bundle install" that takes longer than "gem install nokogiri"

Usage
=====

1. Set up a bucket on S3 in the US Standard region (us-east-1) (and possibly a new user via IAM)

2. Setup your .travis.yml to include the following (NOTE: this must be done before the next steps)

    ```yaml
    env:
      global:
      - BUNDLE_ARCHIVE="your-bundle-name"
      - AWS_S3_REGION="us-east-1"
      - AWS_S3_BUCKET="your-bucket-name"

    before_install:
    - 'echo ''gem: --no-ri --no-rdoc'' > ~/.gemrc'
    - gem install travis_bundle_cache

    install: travis_bundle_install

    after_script:
    - travis_bundle_cache
    ```

3. Install the travis gem (not the travis_bundle_cache gem)

    ```bash
    gem install travis
    ```

4. Log into Travis (from inside your project respository directory)

    ```bash
    travis login --auto
    ```

5. Encrypt your S3 credentials (be sure to add your actual credentials inside the double quotes)

    ```bash
    travis encrypt AWS_S3_KEY="" AWS_S3_SECRET="" --add
    ```

Enjoy faster builds

Contributions
=============

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

Thanks
======

Most of the credit for this gem goes to Random Errata and [this](http://randomerrata.com/post/45827813818/travis-s3) blog post
