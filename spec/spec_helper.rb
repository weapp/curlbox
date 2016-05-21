require 'securerandom'
require 'faraday'

ENV["APP_ENV"] ||= "test"

p ::File.expand_path("../../curlbox", __FILE__)

require ::File.expand_path("../../curlbox", __FILE__)

EXECUTION = SecureRandom.uuid.split("-").first

RSpec.configure do |config|
  config.before(:example, user: true) do
    conn.basic_auth('user', 'user')
  end

  config.before(:example, admin: true) do
    conn.basic_auth('admin', 'admin')
  end
end

def doc_with_line
  _, file, line = %r{(.*):(\d+)}.match(caller.first).to_a
  "example at #{file.sub(%r{^#{Dir.pwd}}, ".")}:#{line}"
end

RSpec::Matchers.define :have_status_and_body do |status, body|
  match do |response|
    description { "returns a #{status}, with #{body}" }
    expect(response.status).to eq status
    expect(response.body).to eq body
  end

  failure_message do |actual|
    "status should be #{status}, actual #{actual.status}\n" \
    "body should be: #{body.inspect}, actual: #{actual.body.inspect}"
  end

  description do
    "have status #{status} and body #{body.inspect}"
  end
end

def pretty(hash={})
  "#{JSON.pretty_generate(hash)}\n"
end
