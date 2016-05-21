require 'aws-sdk'

module FileManagers
  class S3
    def initialize(bucket:)
      @bucket = bucket
      @s3 = Aws::S3::Client.new
    end

    def put(path, input)
      @s3.put_object(bucket: @bucket, key: path, body: input)
    end

    def get(path)
      # ["<html><meta http-equiv='refresh' content='0; url=#{url_for(path)}' /></html>"]
      # [302, {location: url_for(path)}, []]
      @s3.get_object(bucket: @bucket, key: path).body
    rescue Aws::S3::Errors::NoSuchKey
      nil
    end

    private

    def url_for(path)
      Aws::S3::Bucket.new(@bucket).object(path)
        .presigned_url(:get, expires_in: 3600)
    end
  end
end
