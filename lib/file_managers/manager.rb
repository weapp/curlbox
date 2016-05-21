module FileManagers
  class Manager
    attr_accessor :adapter, :namespace

    def initialize(options)
      @namespace = options.delete(:namespace)
      @adapter = options.delete(:adapter)
      @adapter = ADAPTERS[adapter].new(options) if adapter.is_a? Symbol
    end

    def post(path, input)
      @adapter.put(extend_path(path), input)
    end

    def put(path, input)
      post(path, input) unless json?(path)

      actual = JSON[read!(path)]
      query = JSON[self.class.as_s(input)]
      merged = StringIO.new "#{JSON.pretty_generate(actual.merge(query))}\n"

      post(path, merged)
    end

    def get(path)
      return get!(path) unless (resource_path = cacheable?(path))
      get!(path, onlyfs: true) || get_and_post(resource_path, path)
    end

    def delete(path)
      @adapter.delete(extend_path(path)) rescue nil
    end

    def cacheable?(path)
      %r{^/cache/(.*?)(/.*)$}.match(path).to_a.last
    end

    def json?(path)
      path =~ %r{^/json/} || path =~ %r{.json$}
    end

    private

    def get_and_post(resource_path, path)
      for_save, for_return = dup_io(get!(resource_path))
      post(path, for_save) if for_save
      for_return
    end

    def get!(path, onlyfs: false)
      content = @adapter.get(extend_path(path))
      return content if onlyfs
      content || (json?(path) ? self.class.as_io("{\n}\n") : nil)
    end

    def read!(*args)
      self.class.as_s(get!(*args))
    end

    def dup_io(io)
      str = self.class.as_s(io)
      [self.class.as_io(str), self.class.as_io(str)]
    end

    def extend_path(path)
      "files/#{namespace}#{path}"
    end

    def self.as_io(buffer)
      buffer && (buffer.is_a?(String) ? StringIO.new(buffer) : buffer)
    end

    def self.as_s(buffer)
      return unless buffer
      buffer.rewind if buffer.respond_to?(:rewind)
      return buffer.read if buffer.respond_to?(:read)
      return buffer.each.to_a.join if buffer.respond_to?(:each)
      buffer.to_s
    end

  end
end
