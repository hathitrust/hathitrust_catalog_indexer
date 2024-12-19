# frozen_string_literal: true

require "semantic_logger"
require_relative "logfile_defaults"

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

    def add_file_appender
      logfile_path = case @log_file
      when "daily", "today"
        LogfileDefaults.daily
      when "full"
        LogfileDefaults.full
      when String
        LogfileDefaults.logdir + "/#{@log_file}"
      end

      if logfile_path
        SemanticLogger.add_appender(file_name: logfile_path.to_s, level: min_level, formatter: Formatter.new)
      end
    end

    def add_stderr_appender
      unless @quiet
        SemanticLogger.add_appender(io: $stderr, level: :error, formatter: Formatter.new)
      end
    end

    def add_stdout_appender
      unless @quiet
        SemanticLogger.add_appender(io: $stdout, level: min_level, formatter: Formatter.new)
      end
    end

    def logger(owner: "CICTL")
      # Force SemanticLogger to run in main thread. This is only for testing.
      # The alternative -- logger.close -- makes the GitHub testing environment very unhappy.
      SemanticLogger.sync! if ENV["CICTL_SEMANTIC_LOGGER_SYNC"]
      # If we use more than one factory (as happens in the tests but not yet in the main code) we get warnings
      # "Ignoring attempt to add a second console appender: … since it would result in duplicate console output."
      # Lazily apply SemanticLogger config setup here instead of the initializer
      # to make sure no one changes the appenders before the logger is created.
      SemanticLogger.clear_appenders!
      SemanticLogger.default_level = min_level

      Pathname.new(LogfileDefaults.logdir).mkpath

      if @log_file == "-"
        add_stdout_appender
      else
        add_file_appender
        add_stderr_appender
      end

      SemanticLogger[owner]
    end

    def min_level
      @verbose ? :debug : :info
    end
  end
end
