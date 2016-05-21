require 'fileutils'

module FileManagers
  class FS
    def initialize(_opts={})
    end

    def put(path, input)
      FileUtils.mkdir_p File.dirname path
      IO.copy_stream(input, path)
    end

    def read(path)
      return unless File.exist?(path)
      File.foreach(path)
    end
  end
end
