module FileManagers
  class Memory
    attr_reader :data

    def initialize(_opts = {})
      @data = {}
    end

    def put(path, input)
      data[path] = input.to_a.join
    end

    def get(path)
      data[path] && StringIO.new(data[path])
    end

    def delete(path)
      data.delete_if { |k, _v| k =~ %r{^#{path}(/.*)?} }
    end
  end

  adapters[:memory] = Memory
end
