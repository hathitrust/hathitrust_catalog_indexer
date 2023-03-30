# frozen_string_literal: true

require "date"
require "date_named_file"
require "dotenv"
require "pry"
require "socket"
require "thor"
require "traject"
require "yaml"
require "zlib"

require_relative "cictl/collection_map"
require_relative "cictl/date_extra"
require_relative "cictl/delete_command"
require_relative "cictl/deleter"
require_relative "cictl/error"
require_relative "cictl/index_command"
require_relative "cictl/indexer"
require_relative "cictl/logger"
require_relative "cictl/services"
require_relative "cictl/solr_client"

unless ENV["NO_DB"]
  require_relative "ht_traject/ht_dbh"
end

module CICTL
  class CICTL < Thor
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
      Dotenv.load
      super args, local_options, config
      Services.register(:logger) do
        Logger.logger(verbose: options["verbose"], log_file: options["log"])
      end
    end

    desc "delete SUBCOMMAND ARGS", "Delete some or all Solr records"
    subcommand "delete", DeleteCommand

    desc "index SUBCOMMAND ARGS", "Index a set of records from a file or date"
    subcommand "index", IndexCommand

    # standard:disable Lint/Debugger
    desc "pry", "Open a pry-shell with environment loaded"
    def pry
      binding.pry
    end
    # standard:enable Lint/Debugger
  end
end
