module Controllers
  class Get < AppController
    def render
      content = app.manager.get(path)
      return error(404) unless content
      [200, {}, content]
    end
  end
end
