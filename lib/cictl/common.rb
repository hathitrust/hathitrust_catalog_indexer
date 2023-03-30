# frozen_string_literal: true

require_relative "services"

module CICTL
  # Mix-in with mainly accessors to Services plus some miscellaneous junk
  # that probably should find a different home.
  module Common
    # Read the data directory from ENV falling back to the default.
    def data_directory
      ENV["DDIR"] || "/htsolr/catalog/prep"
    end

    def fatal(message)
      logger.fatal message
      raise CICTLError, message
    end

    def home
      Services[:home]
    end

    def logger
      Services[:logger]
    end

    def solr_client
      Services[:solr]
    end
  end
end
