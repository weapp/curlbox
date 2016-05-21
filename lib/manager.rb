class Manager
  attr_accessor :adapter, :namespace

  def initialize(adapter=nil, options={bucket: ENV["BUCKET"]})
    @namespace = options.delete(:namespace)
    @adapter ||= adapter_class(adapter || (ENV["BUCKET"] ? :s3 : :fs)).new(options)
  end

  def post(path, input)
    @adapter.put(extend_path(path), input)
  end

  def put(path, input)
    post(path, input) unless json?(path)

    actual = JSON[read!(path)]
    query = JSON[input.read]
    merged = StringIO.new "#{JSON.pretty_generate(actual.merge(query))}\n"

    post(path, merged)
  end

  def get(path)
    return get!(path) unless (resource_path = cacheable?(path))
    get!(path, onlyfs: true) || get_and_post(resource_path, path)
  end

  def get_and_post(resource_path, path)
    for_save, for_return = dup_io(get!(resource_path))
    post(path, for_save) if for_save
    for_return
  end


  private

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

  def cacheable?(path)
    %r{^/cache/(.*?)(/.*)$}.match(path).to_a.last
  end

  def extend_path(path)
    "files/#{namespace}#{path}"
  end

  def adapter_class(adapter)
    { s3: FileManagers::S3,
      fs: FileManagers::FS,
      memory: FileManagers::Memory }[adapter]
  end

  def self.as_io(buffer)
    buffer && (buffer.is_a?(String) ? StringIO.new(buffer) : buffer)
  end

  def self.as_s(buffer)
    return unless buffer
    return buffer.read if buffer.respond_to?(:read)
    return buffer.each.to_a.join if buffer.respond_to?(:each)
    buffer.to_s
  end

  def json?(path)
    path =~ %r{^/json/} || path =~ %r{.json$}
  end

  # def actual
  #   JSON[app.manager.get(path).each.to_a.join] rescue {}
  # end

  # def query
  #   JSON[input.get]
  # end

  # def merged
  #   StringIO.new "#{JSON.pretty_generate(actual.merge(query))}\n"
  # end
end
