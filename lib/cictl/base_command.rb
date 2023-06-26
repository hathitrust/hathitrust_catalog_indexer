# frozen_string_literal: true

require "thor"
require_relative "common"

module CICTL
  class BaseCommand < Thor
    include Common

    class_option :verbose, type: :boolean,
      desc: "Emit 'debug' in addition to 'info' log entries"
    class_option :log, type: :string,
      desc: "Log to <logfile> instead of STDOUT/STDERR",
      banner: "<logfile>"
  end
end
