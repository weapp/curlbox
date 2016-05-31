#!/usr/bin/env ruby

require 'uri'
require 'logger'

require 'rack'
require 'rack/server'

Dir[File.dirname(__FILE__) + "/lib/**/*.rb"].sort.each { |file| require file }

ADMINS = {'admin' => 'admin'}
VISITORS = {'user' => 'user'}

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
      use Controllers::Router
      run self
    end
  end
end
