#!/usr/bin/env ruby

require 'uri'
require 'logger'

require 'rack'
require 'rack/server'

Dir[File.dirname(__FILE__) + "/lib/**/*.rb"].sort.each { |file| require file }

class CacheMiddleware < Controllers::AppController
  attr_accessor :cache_key, :new_path

  def render
    return error(405) if cacheable? && !["GET", "DELETE"].include?(env["REQUEST_METHOD"])
    nxt.(env)
  end

  def cacheable?
    %r{^/cache/(.*?)(/.*)$}.match(path).to_a.last
  end
end

class ServerCurlBoxMiddleware < Controllers::AppController
  def render
    nxt.(env).tap { |_s, h, _b| h["Server"] = "CurlBox" }
  end
end


class CurlBox < Rack::Builder
  attr_accessor :manager, :logger, :admins, :visitors, :env

  def initialize(adapter: nil, logger: nil)
    @env = (ENV["CURLBOX_ENV"] || ENV["APP_ENV"] || ENV["RACK_ENV"] || "development").to_sym

    adapter ||= if env == :test
                  :memory
                elsif ENV["BUCKET"]
                  :s3
                else
                  :memory
                end

    @manager = Manager.new(adapter: adapter,
                           namespace: @env,
                           bucket: ENV["BUCKET"])

    @logger = logger || Logger.new(STDOUT)

    @admins = {'admin' => 'admin'}
    @visitors = admins.merge('user' => 'user')

    super do
      use ServerCurlBoxMiddleware
      use CacheMiddleware
      use Controllers::Router
      run self
    end
  end
end
