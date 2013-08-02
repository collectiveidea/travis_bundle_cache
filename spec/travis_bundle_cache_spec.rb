require "spec_helper"

describe TravisBundleCache::Cache do
  before(:each) do
    ENV["TRAVIS_REPO_SLUG"]    = "owner/repo"
    ENV["TRAVIS_BUILD_DIR"]    = "/home/travis/owner/repo"
    ENV["AWS_S3_KEY"]          = "AN_ACCESS_KEY_ID"
    ENV["AWS_S3_SECRET"]       = "AN_SECRET_ACCESS_KEY"
    ENV["AWS_S3_BUCKET"]       = "a-bucket-name"

    @uname = `uname -m`.strip
    @cache = TravisBundleCache::Cache.new
  end

  describe 'install' do
    before(:each) do
      @cache.stub(:run_command)
    end

    it 'tries to download an available bundle archive' do
      expect(@cache).to receive(:run_command).once.with(/\Acd ~ && wget -O "remote_owner-repo-#{@uname}\.tgz" "https:\/\/a-bucket-name\.s3\.amazonaws\.com\/owner-repo-#{@uname}.tgz\?AWSAccessKeyId=AN_ACCESS_KEY_ID&Expires=[0-9]+&Signature=[^"]+" && tar -xf "remote_owner-repo-#{@uname}\.tgz"\Z/)

      @cache.install
    end

    it 'tries to download an available bundle archive signature' do
      expect(@cache).to receive(:run_command).once.with(/\Acd ~ && wget -O "remote_owner-repo-#{@uname}\.tgz.sha2" "https:\/\/a-bucket-name\.s3\.amazonaws\.com\/owner-repo-#{@uname}.tgz.sha2\?AWSAccessKeyId=AN_ACCESS_KEY_ID&Expires=[0-9]+&Signature=[^"]+"\Z/)

      @cache.install
    end

    it 'installs the bundle' do
      expect(@cache).to receive(:run_command).once.with("bundle install --without development production --path=~\/.bundle", retry: true)

      @cache.install
    end
  end

  describe 'cache_bundle' do
    before(:each) do
      ENV['TRAVIS_PULL_REQUEST'] = 'false'
      ENV['TRAVIS_BRANCH']       = 'master'

      @cache.stub(:puts)
      @cache.stub(:run_command)
      AWS::S3::S3Object.any_instance.stub(:write)

      FileUtils.mkdir_p(ENV["TRAVIS_BUILD_DIR"])
      File.open(File.join(ENV["TRAVIS_BUILD_DIR"], 'Gemfile.lock'), 'w') {|f| f.puts "Some lock contents" }
    end

    it 'builds a new archive if one does not already exist' do
      expect(@cache).to receive(:archive_and_upload_bundle).once.with(no_args)

      @cache.cache_bundle
    end

    it 'builds a new archive if the sha has changed' do
      FileUtils.mkdir_p("~/")
      File.open(File.expand_path("~/remote_owner-repo-#{@uname}.tgz.sha2"), 'w') {|f| f.print "old sha hash" }
      expect(@cache).to receive(:archive_and_upload_bundle).once.with(no_args)

      @cache.cache_bundle
    end

    it 'does not build a new archive if the sha matches' do
      FileUtils.mkdir_p("~/")
      File.open(File.expand_path("~/remote_owner-repo-#{@uname}.tgz.sha2"), 'w') {|f| f.print "be7b966bd555fffd27c11f2557484501ad2ed482f1b6164457433800e163ae29" }
      expect(@cache).to receive(:archive_and_upload_bundle).never
      expect(@cache).to receive(:puts).with("=> There were no changes, doing nothing")

      @cache.cache_bundle
    end

    it 'does not build a new archive for pull requests' do
      ENV['TRAVIS_PULL_REQUEST'] = '1'
      expect(@cache).to receive(:archive_and_upload_bundle).never
      expect(@cache).to receive(:puts).with("=> This is a pull request, doing nothing")

      @cache.cache_bundle
    end

    it 'does not build a new archive for a non master brnach' do
      ENV['TRAVIS_BRANCH'] = 'not-master'
      expect(@cache).to receive(:archive_and_upload_bundle).never
      expect(@cache).to receive(:puts).with("=> This is not the master branch, doing nothing")

      @cache.cache_bundle
    end
  end

  describe 'archive_and_upload_bundle' do
    before(:each) do
      @cache.stub(:puts)
      @cache.stub(:run_command)
      AWS::S3::S3Object.any_instance.stub(:write)

      @cache.instance_variable_set(:@bundle_digest, 'be7b966bd555fffd27c11f2557484501ad2ed482f1b6164457433800e163ae29')
    end

    it 'runs bundle clean if there was an old archive' do
      @cache.instance_variable_set(:@old_digest, 'non-empty-string')
      expect(@cache).to receive(:run_command).with("bundle clean")

      @cache.archive_and_upload_bundle
    end

    it 'archives the current bundle directory' do
      expect(@cache).to receive(:run_command).with(%{cd ~ && tar -cjf "owner-repo-#{@uname}.tgz" .bundle}, exit_on_error: true)

      @cache.archive_and_upload_bundle
    end

    it 'sends the correct files to S3' do
      storage = {
        "owner-repo-#{@uname}.tgz"      => double(AWS::S3::S3Object),
        "owner-repo-#{@uname}.tgz.sha2" => double(AWS::S3::S3Object)
      }
      @cache.stub(:storage).and_return(storage)

      expect(storage["owner-repo-#{@uname}.tgz"]).to receive(:write).with(Pathname.new(File.expand_path("~/owner-repo-#{@uname}.tgz")), reduced_redundancy: true)
      expect(storage["owner-repo-#{@uname}.tgz.sha2"]).to receive(:write).with("be7b966bd555fffd27c11f2557484501ad2ed482f1b6164457433800e163ae29", content_type: 'text/plain', reduced_redundancy: true)

      @cache.archive_and_upload_bundle
    end
  end
end
