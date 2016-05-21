module Controllers
  class Post < AppController
    def render
      app.manager.post(path, input)
      [200, {}, ["#{path}\n"]]
    end
  end
end
