module FileManagers
  class Memory
    attr_reader :data

    def initialize(_opts={})
      @data = {}
    end

    def put(path, input)
      data[path] = input.to_a.join
    end

    def read(path)
      data[path] && StringIO.new(data[path])
    end
  end
end
