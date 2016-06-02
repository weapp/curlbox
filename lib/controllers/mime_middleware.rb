require "rack/file"
require "rack/utils"

module Controllers
  class MimeMiddleware < Controllers::AppController
    def render
      nxt.(env).tap do |status, headers, _b|
        next unless status == 200
        headers["Content-Type"] ||=
          Rack::Mime.mime_type(::File.extname(path), 'text/html')
      end
    end
  end
end
