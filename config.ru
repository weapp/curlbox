#!/usr/bin/env ruby

require 'uri'
require 'securerandom'
require 'rack'
require 'rack/server'
require 'fileutils'

ADMINS = {'admin' => 'admin'}
VISITORS = ADMINS.merge('user' => 'user')

class CurlBox
  attr_accessor :path, :input

  def self.call(env)
    new(env).call
  end

  def initialize(env)
    @method = env["REQUEST_METHOD"] == "POST" ? :post : :get
    @path = path_from_env(env)
    @input = env["rack.input"]
    @env = env
  end

  def post?
    @method == :post
  end

  def get?
    @method == :get
  end

  def call(*)
    if post?
      basic_auth(method(:post), ADMINS).call(@env)
    elsif get? && path =~ %r{^public/}
      get
    elsif get?
      basic_auth(method(:get), VISITORS).call(@env)
    end
  end

  def get(*)
    [200, {}, [File.read(file_path)]]
  rescue Errno::ENOENT
    error404
  rescue
    error500
  end

  def post(*)
    FileUtils.mkdir_p File.dirname file_path
    File.open(file_path, 'wb') { |file| file.write(input.read) }
    [200, {}, ["#{path}\n"]]
  rescue => error
    p error
    error400
  end

  def error400(*); [400, {}, ["Error"]]; end
  def error404(*); [404, {}, ["Not Found"]]; end
  def error500(*); [500, {}, ["Error"]]; end

  private

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

 # curl -XPOST http://localhost:9292/filename --data-binary "@filepath"

 run CurlBox
