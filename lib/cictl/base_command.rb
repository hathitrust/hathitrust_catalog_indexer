# frozen_string_literal: true

require "thor"
require_relative "common"

module CICTL
  class BaseCommand < Thor
    include Common

    class_option :verbose, type: :boolean,
      desc: "Emit 'debug' in addition to 'info' log entries",
      default: false
    class_option :log, type: :string,
      desc: "Log to <logfile> instead of STDOUT/STDERR",
      banner: "<logfile>"

    def initialize(args = [], local_options = {}, config = {})
      # For creating the default CICTL logger as well as one for calling Traject
      # an any other subcomponents we want to stick a custom logger into.
      HathiTrust::Services.register(:logger_factory) do
        LoggerFactory.new(verbose: options[:verbose], log_file: options[:log])
      end
      # Default CICTL logger
      HathiTrust::Services.register(:logger) do
        HathiTrust::Services[:logger_factory].logger
      end
      super args, local_options, config
    end
  end
end
