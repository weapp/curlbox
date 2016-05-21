module Controllers
  class AppController
    attr_accessor :nxt, :env, :app

    def initialize(nxt)
      @nxt = nxt
      @app = nxt.respond_to?(:app) ? nxt.app : nxt
    end

    def call(env)
      @env = env
      render
    end

    private

    def error400(*); [400, {}, ["Bad Request\n"]]; end
    def error404(*); [404, {}, json? ? ["{\n}\n"] : ["Not Found\n"] ]; end
    def error405(*); [405, {}, ["Method not allowed\n"] ]; end
    def error500(*); [500, {}, ["Error\n"]]; end

    def json?
      path =~ %r{^/json/} || path =~ %r{.json$}
    end

    def basic_auth(nxt, users)
      Rack::Auth::Basic.new(nxt, "Protected Area") do |user, pass|
        users[user] && users[user] == pass
      end
    end

    def input
      env["rack.input"].instance_eval("@input") || env["rack.input"]
    end

    def path=(pth)
      env["c.path"] = nil
      env['PATH_INFO'] = pth
    end

    def path
      env['PATH_INFO']
    end

  end
end
