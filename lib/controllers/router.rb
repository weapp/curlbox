module Controllers
  class Router < AppController
    def render
      app.logger.info "#{app.manager.class}##{env["REQUEST_METHOD"]} > #{path}"
      controller = case env["REQUEST_METHOD"]
            when "POST" then basic_auth(Post.new(nxt), nxt.admins)
            when "PUT" then basic_auth(Put.new(nxt), nxt.admins)
            when "GET" then path =~ %r{^/(cache/)?public/} \
              ? Get.new(nxt)
              : basic_auth(Get.new(nxt), nxt.visitors)
            end
      controller ? controller.(env) : error(404)
    rescue => error
      app.logger.error error
      error(500)
    end
  end
end
