module Loggable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def logger(path: nil)
      @logger ||= if path
        FileUtils.mkdir_p(File.dirname(path))
        Logger.new(path)
      else
        Logger.new($stdout)
      end
    end

    def log(message, method_name = nil, lineno = nil, file = nil)
      method_name ||= "unknown_method"
      lineno ||= 0
      file ||= "unknown_file"

      prefix_parts = []
      prefix_parts << "[#{file}:#{lineno}]"
      prefix_parts << _loggable_prefix.gsub('%method%', method_name)

      logger.info "#{prefix_parts.join(' ')} #{message}"
    end

    def loggable(prefix = nil)
      @prefix ||= prefix&.gsub('%class%', name.split('::').last)
    end

    def _loggable_prefix
      @prefix ||= begin
        namespace, _, klass = name.rpartition('::')
        "[#{namespace}] [#{klass}] [%method%]"
      end
    end
  end

  def log(message)
    caller_info = caller_locations(1, 1).first
    method_name = caller_info.label
    lineno = caller_info.lineno
    file = caller_info.absolute_path || caller_info.path

    self.class.log(message, method_name, lineno, file)
  end
end