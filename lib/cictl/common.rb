# frozen_string_literal: true

require_relative "../services"

module CICTL
  # Mix-in with mainly accessors to Services plus some miscellaneous junk
  # that probably should find a different home.
  module Common
    # Read the data directory from ENV falling back to the default.
    def data_directory
      HathiTrust::Services[:data_directory]
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

    # @return [CICTL::SolrClient]
    def solr_client
      HathiTrust::Services[:solr]
    end

    # Coerce a user-supplied Date or String to a Date within a block.
    def with_date(obj)
      date = if obj.respond_to?(:to_date)
        obj.to_date
      else
        begin
          Date.parse(obj.to_s)
        rescue => e
          raise CICTLError.new "unable to parse \"#{obj}\" (#{e})"
        end
      end

      yield date
    end
  end
end
