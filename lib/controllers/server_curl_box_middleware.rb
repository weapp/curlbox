module Controllers
  class ServerCurlBoxMiddleware < Controllers::AppController
    def render
      nxt.(env).tap { |_s, h, _b| h["Server"] = "CurlBox" }
    end
  end
end
