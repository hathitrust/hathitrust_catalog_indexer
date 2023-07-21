# frozen_string_literal: true

require "canister"
require "dotenv"
require "pathname"

require_relative "cictl/solr_client"
require_relative "ht_traject/ht_dbh"

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

  Services.register(:db) do
    DBH.connect
  end
end
