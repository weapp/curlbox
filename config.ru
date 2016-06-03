#!/usr/bin/env ruby

require ::File.expand_path("../curlbox", __FILE__)

# curl -XPOST http://localhost:9292/filename --data-binary "@file_path"

run CurlBox.new
