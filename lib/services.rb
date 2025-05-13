# frozen_string_literal: true

require "canister"
require "dotenv"
require "sequel"

require_relative "cictl/solr_client"
require_relative "ht_traject/redirects"
require_relative "ht_traject/print_holdings_api"
require_relative "ht_traject/mock_redirects"
require_relative "ht_traject/mock_print_holdings"
require_relative "ht_traject/mock_oclc_resolution"
require_relative "ht_traject/oclc_resolution"

# Load order to honor dependencies:
#  Home so we know where to look for everything else.
#  Env so we can set up DB and Solr config
module HathiTrust
  HOME = File.expand_path(File.join(__dir__, "..")).freeze

  module Env
    # Load env file and env.local if it exists.
    # Precedence from high to low:
    #  ENV set by Docker, docker-compose, kubectl, etc.
    #  config/env.local for non-k8s production use
    #  config/env which has defaults for development and testing
    def env_file
      @env_file ||= File.join(HOME, "config", "env")
    end

    def env_local_file
      @env_local_file ||= File.join(HOME, "config", "env.local")
    end

    module_function :env_file, :env_local_file
    # From the Dotenv README: "The first value set for a variable will win."
    Dotenv.load env_local_file, env_file
  end

  Services = Canister.new

  Services.register(:solr_url) do
    ENV["SOLR_URL"]
  end

  Services.register(:solr) do
    CICTL::SolrClient.new
  end

  # The top-level repo path.
  # In Docker likely to be "/app/"
  # Appears as $TDIR in the old bin/ shell scripts
  Services.register(:home) do
    HOME
  end

  Services.register(:data_directory) do
    ENV["DDIR"] || "/htsolr/catalog/prep"
  end

  Services.register(:logfile_directory) do
    default = "#{HOME}/logs"
    ENV["LOG_DIR"] || default
  end

  Services.register(:journal_directory) do
    (ENV["JOURNAL_DIRECTORY"] || File.join(HOME, "journal")).tap do |dir|
      if !File.exist?(dir)
        FileUtils.mkdir dir
      end
    end
  end

  Services.register(:redirect_file) do
    # Start migrating from redirect_file to REDIRECT_FILE on principle of least surprise
    ENV["redirect_file"] || ENV["REDIRECT_FILE"] || Redirects.default_redirects_file
  end

  Services.register(:db) do
    Sequel.connect(Services[:db_connection_string], login_timeout: 2, pool_timeout: 100, max_connections: 6)
  end

  # From the Sequel Docs (https://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html):
  # Note that when using a JDBC adapter, the best way to use Sequel is via Sequel.connect
  # using a connection string, NOT Sequel.jdbc
  Services.register(:db_connection_string) do
    "jdbc:mysql://#{ENV["MARIADB_HT_RO_HOST"]}/#{ENV["MARIADB_HT_RO_DATABASE"]}? \
    user=#{ENV["MARIADB_HT_RO_USERNAME"]}&password=#{ENV["MARIADB_HT_RO_PASSWORD"]}& \
    useTimezone=true&serverTimezone=UTC"
  end

  Services.register(:no_db?) { ENV["NO_DB"] || ENV["NO_EXTERNAL_DATA"] }
  Services.register(:no_redirects?) { ENV["NO_REDIRECTS"] || ENV["NO_EXTERNAL_DATA"] }

  Services.register(:print_holdings) do
    Services[:no_db?] ? MockPrintHoldings : PrintHoldings
  end

  Services.register(:oclc_resolution) do
    Services[:no_db?] ? MockOCLCResolution : OCLCResolution
  end

  Services.register(:redirects) do
    Services[:no_redirects?] ? MockRedirects.new : Redirects.new
  end

  Services.register(:collection_map) do
    CICTL::CollectionMap.new.to_translation_map
  end

  Services.register(:job_name) { ENV.fetch("JOB_NAME", $PROGRAM_NAME) }
end
