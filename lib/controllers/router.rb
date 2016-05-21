module Controllers
  class Router < AppController
    def render
      app.logger.info "#{app.manager.adapter.class}##{env["REQUEST_METHOD"]} > #{path}"
      controller = case env["REQUEST_METHOD"]
            when "POST" then basic_auth(Post.new(nxt), app.admins)
            when "PUT" then basic_auth(Put.new(nxt), app.admins)
            when "GET" then path =~ %r{^/(cache/)?public/} \
              ? Get.new(nxt)
              : basic_auth(Get.new(nxt), app.visitors)
            end
      controller ? controller.(env) : error(404)
    rescue => error
      app.logger.error error
      error(500)
    end

    def basic_auth(nxt, users)
      Rack::Auth::Basic.new(nxt, "Protected Area") do |user, pass|
        users[user] && users[user] == pass
      end
    end
  end
end
