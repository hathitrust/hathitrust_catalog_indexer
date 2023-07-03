# frozen_string_literal: true

require "pry"
require "thor"

require_relative "../services"
require_relative "delete_command"
require_relative "index_command"
require_relative "solr_command"

module CICTL
  class Commands < Thor
    def self.exit_on_failure?
      true
    end

    # Note: the initializer that sets up the logger factory and default logger
    # has moved to BaseCommand since it owns the --log and --verbose options.
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
