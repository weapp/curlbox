module Controllers
  class Get < AppController
    def render
      content = app.manager.read(path)
      return error404 unless content
      [200, {}, content]
    end
  end
end
