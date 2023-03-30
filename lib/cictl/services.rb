# frozen_string_literal: true

require "canister"

require_relative "solr_client"

module CICTL
  Services = Canister.new
  Services.register(:solr) do
    SolrClient.new
  end

  # The top-level repo path.
  # In Docker likely to be "/app/"
  # Appears as $TDIR in the shell scripts
  Services.register(:home) do
    File.expand_path(File.dirname(__FILE__) + "/../..")
  end
end
