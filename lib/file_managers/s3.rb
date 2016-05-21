require 'aws-sdk'

module FileManagers
  class S3
    def initialize(bucket:)
      @bucket_name = bucket
      @bucket = Aws::S3::Bucket.new(@bucket_name)
      @s3 = Aws::S3::Client.new
    end

    def put(path, input)
      @s3.put_object(bucket: @bucket_name, key: path, body: input)
    end

    def get(path)
      # ["<html><meta http-equiv='refresh' content='0; url=#{url_for(path)}' /></html>"]
      # [302, {location: url_for(path)}, []]
      @s3.get_object(bucket: @bucket_name, key: path).body
    rescue Aws::S3::Errors::NoSuchKey
      nil
    end

    def delete(path)
      require "pry"
      @s3.delete_object(bucket: @bucket_name, key: "#{path}")
      objects = @s3.list_objects(bucket: @bucket_name, prefix: "#{path}/").contents.map do |obj|
        { key: obj.key }
      end
      @bucket.delete_objects(delete: {  objects: objects, quiet: false }) if !objects.empty?
    end

    private

    def url_for(path)
      Aws::S3::Bucket.new(@bucket_name).object(path)
        .presigned_url(:get, expires_in: 3600)
    end
  end
end
