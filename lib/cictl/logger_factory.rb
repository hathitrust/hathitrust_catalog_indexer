# frozen_string_literal: true

require "semantic_logger"

module CICTL
  class LoggerFactory
    class Formatter < SemanticLogger::Formatters::Default
      # Return the complete log level name in uppercase instead of one letter
      def level
        log.level.upcase
      end
    end

    def initialize(verbose: false, log_file: nil, quiet: false)
      @verbose = verbose
      @log_file = log_file
      @quiet = quiet
    end

    def logger(owner: "CICTL")
      # If we use more than one factory (as happens in the tests but not yet in the main code) we get warnings
      # "Ignoring attempt to add a second console appender: … since it would result in duplicate console output."
      # Lazily apply SemanticLogger config setup here instead of the initializer
      # to make sure no one changes the appenders before the logger is created.
      SemanticLogger.clear_appenders!
      SemanticLogger.default_level = min_level

      Pathname.new(LogfileDefaults.logdir).mkpath

      if @log_file
        SemanticLogger.add_appender(file_name: @log_file, level: min_level)
      end
      unless @quiet
        SemanticLogger.add_appender(io: $stderr, level: :error, formatter: Formatter.new)
      end
      SemanticLogger[owner]
    end

    def min_level
      @verbose ? :debug : :info
    end
  end
end
