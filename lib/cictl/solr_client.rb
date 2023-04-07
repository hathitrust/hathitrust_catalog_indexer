# frozen_string_literal: true

require "rsolr"

module CICTL
  class SolrClient
    attr_reader :solr
    def initialize(rsolr = nil)
      @solr = rsolr
      @solr ||= RSolr.connect url: solr_url
    end

    def to_s
      "CICTL::SolrClient for #{solr_url}, #{count} documents"
    end

    # Count all records including those with the "deleted" flag set.
    def count(q = "*:*")
      solr_params = {q: q, wt: "ruby", rows: 1}
      @solr.get("select", params: solr_params)["response"]["numFound"]
    end

    # Count only records with the "deleted" flag.
    def count_deleted
      count "deleted:true"
    end

    def commit!
      @solr.commit
      self
    end

    # FIXME: not happy about the naming convention.
    # This removes full records but leaves intact the tombstoned "deletes"
    def empty_records!
      @solr.delete_by_query "deleted:(NOT true)"
      self
    end

    # FIXME: ditto above re not happy about the naming convention.
    def empty!
      @solr.delete_by_query "*:*"
      self
    end

    def set_deleted(ids)
      solr_data = Array(ids).map { |id| deleted_id id }
      @solr.update data: solr_data.to_json, headers: {"Content-Type" => "application/json"}
    end

    private

    def deleted_id(id)
      {id: id, deleted: true}
    end

    def solr_url
      ENV["SOLR_URL"]
    end
  end
end
