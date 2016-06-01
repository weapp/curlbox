module Controllers
  class Router < AppController
    def render
      app.logger.info "#{app.manager.adapter.class}##{env["REQUEST_METHOD"]} > #{path}"
      routes(
        ["POST",   //, app.admins,               Post],
        ["PUT",    //, app.admins,               Put],
        ["GET",    %r{^/(cache/)?public/}, nil,  Get],
        ["GET",    //, app.visitors,             Get],
        ["DELETE", //, app.admins,               Delete],
        [//,       //, nil,                      Proc.new { error(404) }]
      )
    end

    def basic_auth(nxt, users)
      Rack::Auth::Basic.new(nxt, "Protected Area") do |username, pass|
        users[username] && users[username][:pass] == pass
      end
    end

    def policy(auth)
      (auth && auth[username]) ? auth[username][:policy] : //
    end

    def routes(*routes)
      routes.each do |method, path_regex, auth, ctrl|
        next unless method === env["REQUEST_METHOD"]
        next unless path_regex === path
        next unless policy(auth) === path
        controller = ctrl.respond_to?(:new) ? ctrl.new(nxt) : ctrl
        controller = basic_auth(controller, auth) if auth
        return controller.(env)
      end
    rescue => error
      app.logger.error error
      error(500)
    end
  end
end
