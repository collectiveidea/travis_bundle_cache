require "digest"
require "aws/s3"

module TravisBundleCache
  class Cache
    def initialize
      @architecture        = `uname -m`.strip
      @bundle_archive      = ENV['BUNDLE_ARCHIVE'] || ENV['TRAVIS_REPO_SLUG'].gsub(/\//, '-')
      @file_name           = "#{@bundle_archive}-#{@architecture}.tgz"
      @file_path           = File.expand_path("~/#{@file_name}")
      @lock_file           = File.join(File.expand_path(ENV["TRAVIS_BUILD_DIR"]), "Gemfile.lock")
      @digest_filename     = "#{@file_name}.sha2"
      @old_digest_filename = File.expand_path("~/remote_#{@digest_filename}")
    end

    def install
      run_command %(cd ~ && wget -O "remote_#{@file_name}" "#{storage[@file_name].url_for(:read)}" && tar -xf "remote_#{@file_name}")
      run_command %(cd ~ && wget -O "remote_#{@file_name}.sha2" "#{storage[@digest_filename].url_for(:read)}")
      run_command %(bundle install --without #{ENV['BUNDLE_WITHOUT'] || "development production"} --path=~/.bundle)
    end

    def cache_bundle
      puts "Checking for changes"
      @bundle_digest = Digest::SHA2.file(@lock_file).hexdigest
      @old_digest    = File.exists?(@old_digest_filename) ? File.read(@old_digest_filename) : ""

      if ENV['TRAVIS_PULL_REQUEST'].to_i > 0
        puts "=> This is a pull request, doing nothing"
      elsif ENV['TRAVIS_BRANCH'] != "master"
        puts "=> This is not the master branch, doing nothing"
      elsif @bundle_digest == @old_digest
        puts "=> There were no changes, doing nothing"
      else
        archive_and_upload_bundle
      end
    end

    def archive_and_upload_bundle
      if @old_digest == ""
        puts "=> There was no existing digest, uploading a new version of the archive"
      else
        puts "=> There were changes, uploading a new version of the archive"
        puts "  => Old checksum: #{@old_digest}"
        puts "  => New checksum: #{@bundle_digest}"

        puts "=> Cleaning old gem versions from the bundle"
        run_command "bundle clean"
      end

      puts "=> Preparing bundle archive"
      run_command %(cd ~ && tar -cjf "#{@file_name}" .bundle)

      puts "=> Uploading the bundle"
      storage[@file_name].write(Pathname.new(@file_path), :reduced_redundancy => true)

      puts "=> Uploading the digest file"
      storage[@digest_filename].write(@bundle_digest, :content_type => "text/plain", :reduced_redundancy => true)

      puts "All done now."
    end

    protected

    def run_command(cmd)
      puts "Running: #{cmd}"
      IO.popen(cmd) do |f|
        begin
          print f.readchar while true
        rescue EOFError
        end
      end
    end

    def storage
      @storage ||= AWS::S3.new({
        :access_key_id     => ENV["AWS_S3_KEY"],
        :secret_access_key => ENV["AWS_S3_SECRET"],
        :region            => ENV["AWS_S3_REGION"] || "us-east-1"
      }).buckets[ENV["AWS_S3_BUCKET"]].objects
    end
  end
end
