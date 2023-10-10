# frozen_string_literal: true

require "canister"
require "dotenv"
require "sequel"

require_relative "cictl/solr_client"
require_relative "ht_traject/redirects"
require_relative "ht_traject/ht_mock_print_holdings"
require_relative "ht_traject/ht_print_holdings"

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

  Services.register(:redirect_file) do
    yyyymm = DateTime.now.strftime "%Y%m"
    default_file = "/htapps/babel/hathifiles/catalog_redirects/redirects/redirects_#{yyyymm}.txt.gz"
    # Start migrating from redirect_file to REDIRECT_FILE on principle of least surprise
    ENV["redirect_file"] || ENV["REDIRECT_FILE"] || default_file
  end

  Services.register(:redirects) do
    Redirects.new(Services[:redirect_file])
  end

  Services.register(:db) do
    Sequel.connect(Services[:db_connection_string], login_timeout: 2, pool_timeout: 10, max_connections: 6)
  end

  Services.register(:db_connection_string) do
    "jdbc:mysql://#{ENV["MYSQL_HOST"]}/#{ENV["MYSQL_DATABASE"]}? \
    user=#{ENV["MYSQL_USER"]}&password=#{ENV["MYSQL_PASSWORD"]}& \
    useTimezone=true&serverTimezone=UTC"
  end

  Services.register(:no_db?) do
    ENV["NO_DB"] == "1" or Services[:no_external_data?]
  end

  Services.register(:no_external_data?) do
    ENV["HT_NO_EXTERNAL_DATA"] == "1"
  end

  Services.register(:no_redirects?) do
    ENV["NO_REDIRECTS"] == "1" or Services[:no_external_data?]
  end

  Services.register(:print_holdings) do
    HathiTrust.const_get(Services[:no_db?] ? :MockPrintHoldings : :PrintHoldings)
  end
end
