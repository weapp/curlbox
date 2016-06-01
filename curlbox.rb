#!/usr/bin/env ruby

require 'uri'
require 'logger'

require 'rack'
require 'rack/server'

Dir[File.dirname(__FILE__) + "/lib/**/*.rb"].sort.each { |file| require file }

def parse_env(e)
  Hash[e.scan(%r{(.*?):(.*?)(?:/(.*?)/)?(?:@|$)}).map do |user, pass, policy|
    [user, pass: pass, policy: Regexp.new(policy.to_s, Regexp::IGNORECASE)]
  end]
end

def admins
  ENV['ADMINS'] && parse_env(ENV['ADMINS'])
end

def visitors
  ENV['ADMINS'] && parse_env(ENV['VISITORS'])
end

ADMINS = admins || {'admin' => {pass: 'admin', policy: //}}
VISITORS = visitors || {'user' => {pass: 'user', policy: %r{^/user}}}

class CurlBox < Rack::Builder
  attr_accessor :manager, :logger, :admins, :visitors, :env

  def initialize(options={})
    @env = (ENV["CURLBOX_ENV"] || ENV["APP_ENV"] || ENV["RACK_ENV"] || "development").to_sym

    options[:adapter] ||= if env == :test
                            :memory
                          elsif ENV["BUCKET"]
                            :s3
                          else
                            :fs
                          end

    @manager = FileManagers::Manager.new(adapter: options[:adapter],
                                         namespace: @env,
                                         bucket: ENV["BUCKET"])

    @logger = options.fetch(:logger, Logger.new(STDOUT))
    @logger.level = options.fetch(:log_level, Logger::INFO)

    @admins = options.fetch(:admins, ADMINS)
    @visitors = admins.merge(options.fetch(:admins, VISITORS))

    super do
      use Controllers::ServerCurlBoxMiddleware
      use Controllers::CacheMiddleware
      use Controllers::MimeMiddleware
      use Controllers::Router
      run self
    end
  end
end
