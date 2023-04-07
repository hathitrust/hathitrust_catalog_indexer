# frozen_string_literal: true

require_relative "../services"

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
      HathiTrust::Services[:home]
    end

    def logger
      HathiTrust::Services[:logger]
    end

    def solr_client
      HathiTrust::Services[:solr]
    end
  end
end
