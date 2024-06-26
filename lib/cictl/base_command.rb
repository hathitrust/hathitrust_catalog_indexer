# frozen_string_literal: true

require "thor"
require_relative "common"
require_relative "../services"

module CICTL
  class BaseCommand < Thor
    include Common

    class_option :verbose, type: :boolean,
      desc: "Emit 'debug' in addition to 'info' log entries",
      default: false
    class_option :log, type: :string,
      desc: "Log to <logfile> in <logdir>. Use 'daily' or 'full' for sane defaults.",
      banner: "<logfile>"
    class_option :logdir, type: :string,
      desc: "Location for default logs",
      default: HathiTrust::Services[:logfile_directory]
    class_option :quiet, type: :boolean,
      desc: "Suppress normal output to STDERR",
      default: false

    def initialize(args = [], local_options = {}, config = {})
      # For creating the default CICTL logger as well as one for calling Traject
      # an any other subcomponents we want to stick a custom logger into.
      super args, local_options, config
      # if @options[:logdir]
      #   LogfileDefaults.logdir = @options[:logdir]
      # end

      HathiTrust::Services.register(:logger_factory) do
        LoggerFactory.new(verbose: options[:verbose], log_file: options[:log], quiet: options[:quiet])
      end

      # Default CICTL logger
      HathiTrust::Services.register(:logger) do
        HathiTrust::Services[:logger_factory].logger
      end
    end
  end
end
