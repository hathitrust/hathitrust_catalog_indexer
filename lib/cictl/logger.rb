# frozen_string_literal: true

require "yell"

module CICTL
  class Logger
    def self.logger(verbose: false, log_file: nil)
      Yell.new do |l|
        if log_file
          level = verbose ? (:debug..:fatal) : (:info..:fatal)
          l.adapter :file, log_file, level: level
        else
          level = verbose ? (:debug..:warn) : (:info..:warn)
          l.adapter :stdout, level: level
        end
        # Always log errors to STDERR even if there is a log file.
        l.adapter :stderr, level: %i[error fatal]
      end
    end
  end
end
