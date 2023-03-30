# frozen_string_literal: true

require "rsolr"
require "pry"

module CICTL
  class SolrClient
    def initialize(rsolr = nil)
      @solr = rsolr
      @solr ||= RSolr.connect url: solr_url
    end

    def to_s
      "CICTL::SolrClient for #{solr_url}, #{count} documents"
    end

    def count
      solr_params = {q: "*:*", wt: "ruby", rows: 1}
      @solr.get("select", params: solr_params)["response"]["numFound"]
    end

    def commit!
      @solr.commit
      self
    end

    def empty!
      @solr.delete_by_query "*:*"
      self
    end

    def delete!(ids)
      @solr.delete_by_id Array(ids)
      self
    end

    private

    def solr_url
      ENV["SOLR_URL"]
    end
  end
end
