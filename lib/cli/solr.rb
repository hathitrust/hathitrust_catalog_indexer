require 'hanami/cli'
require 'simple_solr_client'

module HathiTrust
  module CLI
    module Solr
      def solr_url
        ENV["SOLR_URL"] ||= "http://localhost:9033/solr/catalog"
      end
    end
  end
end
