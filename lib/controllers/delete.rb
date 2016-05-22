module Controllers
  class Delete < AppController
    def render
      app.manager.delete(path)
      [200, {}, ["#{path}\n"]]
    end
  end
end
