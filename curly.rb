#!/usr/bin/env ruby

require 'uri'
require 'securerandom'
require 'rack'
require 'rack/server'

class CurlBox
  attr_accessor :path, :input

  def initialize(env)
    @path = path_from_env(env)
    @input = env["rack.input"]
  end

  def self.call(env)
    new(env).send(env["REQUEST_METHOD"] == "POST" ? :post : :get)
  end

  def get
    [200, {}, [File.read(file_path)]]
  rescue Errno::ENOENT
    [404, {}, ["Not Found"]]
  rescue
    [500, {}, ["Error"]]
  end

  def post
    File.open(file_path, 'wb') { |file| file.write(input.read) }
    [200, {}, [path]]
  rescue
    [400, {}, ["Error"]]
  end

  private

  def file_path
    "public/#{path}"
  end

  def path_from_env(env)
    path = env["REQUEST_URI"] && File.expand_path(URI(env["REQUEST_URI"]).path).sub(%r{\A/}, "")
    (!path || path.empty?) ? SecureRandom.uuid : path
  end
end

options = Rack::Server::Options.new.parse!(ARGV)
Rack::Server.start options.merge(app: CurlBox)

# ruby curly.rb -p 4567