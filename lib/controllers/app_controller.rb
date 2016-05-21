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

    def error(code)
      message = case code
                when 400 then "Bad Request"
                when 404 then "Not Found"
                when 405 then "Method not allowed"
                when 500 then "Error"
                else "Error"
                end
      [code, {}, ["#{message}\n"]]
    end

    def basic_auth(nxt, users)
      Rack::Auth::Basic.new(nxt, "Protected Area") do |user, pass|
        users[user] && users[user] == pass
      end
    end

    def input
      env["rack.input"].instance_eval("@input") || env["rack.input"]
    end

    def path
      env['PATH_INFO']
    end
  end
end
