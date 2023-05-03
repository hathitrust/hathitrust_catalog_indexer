# frozen_string_literal: true

require "pry"
require "thor"

require_relative "../services"
require_relative "delete_command"
require_relative "index_command"
require_relative "solr_command"

module CICTL
  class Command < Thor
    include Common

    class_option :verbose, type: :boolean,
      desc: "Emit 'debug' in addition to 'info' log entries"
    class_option :log, type: :string,
      desc: "Log to <logfile> instead of STDOUT/STDERR",
      banner: "<logfile>"

    def self.exit_on_failure?
      true
    end

    def initialize(args = [], local_options = {}, config = {})
      HathiTrust::Services.register(:logger) do
        Logger.logger(verbose: options["verbose"], log_file: options["log"])
      end
      super args, local_options, config
    end

    desc "delete SUBCOMMAND ARGS", "Delete some or all Solr records"
    subcommand "delete", DeleteCommand

    desc "index SUBCOMMAND ARGS", "Index a set of records from a file or date"
    subcommand "index", IndexCommand

    desc "solr SUBCOMMAND ARGS", "Send finds/command directly to solr"
    subcommand "solr", SolrCommand

    # standard:disable Lint/Debugger
    desc "pry", "Open a pry-shell with environment loaded"
    def pry
      binding.pry
    end
    # standard:enable Lint/Debugger
  end
end
