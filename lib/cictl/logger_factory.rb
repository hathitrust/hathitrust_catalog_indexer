# frozen_string_literal: true

require "semantic_logger"

module CICTL
  class LoggerFactory
    def initialize(verbose: false, log_file: nil)
      @verbose = verbose
      @log_file = log_file
    end

    def logger(owner: "CICTL")
      # If we use more than one factory (as happens in the tests but not yet in the main code) we get warnings
      # "Ignoring attempt to add a second console appender: … since it would result in duplicate console output."
      # Lazily apply SemanticLogger config setup here instead of the initializer
      # to make sure no one changes the appenders before the logger is created.
      SemanticLogger.default_level = min_level
      SemanticLogger.clear_appenders!
      if @log_file
        SemanticLogger.add_appender(file_name: @log_file, level: min_level)
      end
      SemanticLogger.add_appender(io: $stderr, level: :error)
      SemanticLogger[owner]
    end

    def min_level
      @verbose ? :debug : :info
    end
  end
end
