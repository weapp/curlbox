module Controllers
  class Put < AppController
    def render
      app.manager.put(path, input)
      [200, {}, ["#{path}\n"]]
    end
  end
end
