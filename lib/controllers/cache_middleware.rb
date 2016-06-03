module Controllers
  class CacheMiddleware < Controllers::AppController
    attr_accessor :cache_key, :new_path

    def render
      return error(405) if cacheable? && !%w(GET DELETE).include?(env["REQUEST_METHOD"])
      nxt.call(env)
    end

    def cacheable?
      app.manager.cacheable?(path)
    end
  end
end
