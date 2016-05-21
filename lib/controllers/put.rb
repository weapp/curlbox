module Controllers
  class Put < AppController
    def render
      return post unless json?
      app.manager.post(path, merged)
      [200, {}, ["#{path}\n"]]
    end

    private

    def actual
      JSON[app.manager.get(path).each.to_a.join] rescue {}
    end

    def query
      JSON[input.read]
    end

    def merged
      StringIO.new "#{JSON.pretty_generate(actual.merge(query))}\n"
    end
  end
end
