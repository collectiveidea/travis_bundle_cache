require "digest"
require "fog"

module TravisBundleCache
  class Cache
    def initialize
      @bucket_name         = ENV["AWS_S3_BUCKET"]
      @architecture        = `uname -m`.strip
      @file_name           = "#{ENV['BUNDLE_ARCHIVE']}-#{@architecture}.tgz"
      @file_path           = File.expand_path("~/#{@file_name}")
      @lock_file           = File.join(File.expand_path(ENV["TRAVIS_BUILD_DIR"]), "Gemfile.lock")
      @digest_filename     = "#{@file_name}.sha2"
      @old_digest_filename = File.expand_path("~/remote_#{@digest_filename}")
    end

    def install
      run_command %(cd ~ && wget -O "remote_#{@file_name}" "https://#{@bucket_name}.s3.amazonaws.com/#{@file_name}" && tar -xf "remote_#{@file_name}")
      run_command %(cd ~ && wget -O "remote_#{@file_name}.sha2" "https://#{@bucket_name}.s3.amazonaws.com/#{@file_name}.sha2")
      run_command %(bundle install --without #{ENV['BUNDLE_WITHOUT'] || "development production"} --path=~/.bundle)
    end

    def cache_bundle
      puts "Checking for changes"
      @bundle_digest = Digest::SHA2.file(@lock_file).hexdigest
      @old_digest    = File.exists?(@old_digest_filename) ? File.read(@old_digest_filename) : ""

      if @bundle_digest == @old_digest
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
      end

      puts "=> Preparing bundle archive"
      `cd ~ && tar -cjf "#{@file_name}" .bundle && split -b 5m -a 3 "#{@file_name}" "#{@file_name}."`

      parts_pattern = File.expand_path(File.join("~", "#{@file_name}.*"))
      parts = Dir.glob(parts_pattern).sort

      puts "=> Uploading the bundle"
      puts "  => Beginning multipart upload"
      response = storage.initiate_multipart_upload @bucket_name, @file_name, { "x-amz-acl" => "public-read" }
      upload_id = response.body['UploadId']
      puts "    => Upload ID: #{upload_id}"

      part_ids = []

      puts "  => Uploading #{parts.length} parts"
      parts.each_with_index do |part, index|
        part_number = (index + 1).to_s
        puts "    => Uploading #{part}"
        File.open part do |part_file|
          response = storage.upload_part @bucket_name, @file_name, upload_id, part_number, part_file
          part_ids << response.headers['ETag']
          puts "      => Uploaded"
        end
      end

      puts "  => Completing multipart upload"
      storage.complete_multipart_upload @bucket_name, @file_name, upload_id, part_ids

      puts "=> Uploading the digest file"
      bucket = storage.directories.new(key: @bucket_name)
      bucket.files.create({
        :body         => @bundle_digest,
        :key          => @digest_filename,
        :public       => true,
        :content_type => "text/plain"
      })

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
      @storage ||= Fog::Storage.new({
        :provider              => "AWS",
        :aws_access_key_id     => ENV["AWS_S3_KEY"],
        :aws_secret_access_key => ENV["AWS_S3_SECRET"],
        :region                => ENV["AWS_S3_REGION"] || "us-east-1"
      })
    end
  end
end
