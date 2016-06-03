module Controllers
  class ServerCurlBoxMiddleware < Controllers::AppController
    def render
      nxt.call(env).tap { |_s, h, _b| h["Server"] = "CurlBox" }
    end
  end
end
