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
        SemanticLogger.add_appender(appender: DualIOAppender.new(level: :error, formatter: :color))
      else
        SemanticLogger.add_appender(appender: DualIOAppender.new(level: min_level, formatter: :color))
      end
      SemanticLogger[owner]
    end

    def min_level
      @verbose ? :debug : :info
    end
  end

  # A variation on the IO appender, writes normal messages to STDOUT
  # and error/fatal messages to STDERR.
  class DualIOAppender < SemanticLogger::Subscriber
    def log(log)
      io = %i[error fatal].include?(log.level) ? $stderr : $stdout
      io.write(formatter.call(log, self) << "\n")
      true
    end

    def flush
      $stdout.flush
      $stderr.flush
    end

    def console_output?
      true
    end
  end
end
