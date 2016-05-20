#!/usr/bin/env ruby

require 'uri'
require 'securerandom'
require 'fileutils'

require 'rack'
require 'rack/server'
require 'aws-sdk'

ADMINS = {'admin' => 'admin'}
VISITORS = ADMINS.merge('user' => 'user')

class FS
  def put(file_path, input)
    FileUtils.mkdir_p File.dirname file_path
    IO.copy_stream(input, file_path)
  end

  def read(file_path)
    raise Errno::ENOENT unless File.exist?(file_path)
    File.foreach(file_path)
  end
end

class AWS
  def initialize(bucket)
    @bucket = bucket
    @s3 = Aws::S3::Client.new
  end

  def put(file_path, input)
    @s3.put_object(bucket: @bucket, key: file_path, body: input)
  end

  def read(file_path)
    # ["<html><meta http-equiv='refresh' content='0; url=#{url_for(file_path)}' /></html>"]
    # [302, {location: url_for(file_path)}, []]
    @s3.get_object(bucket: @bucket, key: file_path).body
  rescue Aws::S3::Errors::NoSuchKey
    raise Errno::ENOENT
  end

  private

  def url_for(file_path)
    Aws::S3::Bucket.new(@bucket).object(file_path)
      .presigned_url(:get, expires_in: 3600)
  end
end

MANAGER = ENV["BUCKET"] ? AWS.new(ENV["BUCKET"]) : FS.new

class CurlBox
  attr_accessor :path, :input

  def self.call(env)
    new(env).call
  end

  def initialize(env)
    @method = env["REQUEST_METHOD"].downcase.to_sym
    p @method
    @path = path_from_env(env)
    @rack_input = env["rack.input"]
    @input = @rack_input.instance_eval("@input") || @rack_input
    @env = env
  end

  def is?(method)
    @method == method
  end

  def call(*)
    if is?(:post)
      basic_auth(method(:post), ADMINS).call(@env)
    elsif is?(:put)
      basic_auth(method(:put), ADMINS).call(@env)
    elsif is?(:get) && path =~ %r{^public/}
      get
    elsif is?(:get)
      basic_auth(method(:get), VISITORS).call(@env)
    else
      error404
    end
  end

  def get(*)
    puts "#{MANAGER.class}#get > #{file_path}"
    [200, {}, MANAGER.read(file_path)]
  rescue Errno::ENOENT
    error404
  rescue => e
    p e
    error500
  end

  def post(*)
    puts "#{MANAGER.class}#post > #{file_path}"
    p input
    MANAGER.put(file_path, input)
    [200, {}, ["#{path}\n"]]
  rescue => error
    p error
    error400
  end

  def put(*)
    return post unless json?
    actual = JSON[MANAGER.read(file_path).each.to_a.join] rescue {}
    query = JSON[input.read]
    merged = StringIO.new "#{JSON[actual.merge(query)]}\n"
    MANAGER.put(file_path, merged)
    merged.rewind
    [200, {}, ["#{path}\n"]]
  rescue => error
    p error
    error400
  end

  def error400(*); [400, {}, ["Bad Request\n"]]; end
  def error404(*); [404, {}, json? ? ["{}\n"] : ["Not Found\n"] ]; end
  def error500(*); [500, {}, ["Error\n"]]; end

  private

  def json?
    path =~ %r{^json/}
  end

  def basic_auth(app, users)
    Rack::Auth::Basic.new(app, "Protected Area") do |user, pass|
      users.fetch(user) == pass
    end
  end

  def file_path
    "files/#{path}"
  end

  def path_from_env(env)
    path = env["REQUEST_URI"] && File.expand_path(URI(env["REQUEST_URI"]).path).sub(%r{\A/}, "")
    (!path || path.empty?) ? SecureRandom.uuid : path
  end
end

 # curl -XPOST http://localhost:9292/filename --data-binary "@file_path"

 run CurlBox
