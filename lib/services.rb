# frozen_string_literal: true

require "canister"
require "dotenv"

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
    #  config/emv.local for non-k8s production use
    #  ENV set by Docker, docker-compose, kubectl, etc.
    #  config/env which has defaults for development and testing
    def env_file
      @env_file ||= File.join(HOME, "config", "env")
    end

    def env_local_file
      @env_local_file ||= File.join(HOME, "config", "env.local")
    end

    module_function :env_file, :env_local_file
    # Okay to clobber ENV with this file because it takes precedence.
    Dotenv.overload env_local_file
    # Don't modify existing values.
    Dotenv.load env_file
  end

  Services = Canister.new
  Services.register(:solr) do
    CICTL::SolrClient.new
  end

  # The top-level repo path.
  # In Docker likely to be "/app/"
  # Appears as $TDIR in the old bin/ shell scripts
  Services.register(:home) do
    HOME
  end

  Services.register(:db) do
    DBH.connect
  end
end
