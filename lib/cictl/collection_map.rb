# frozen_string_literal: true

require "pry"

require_relative "../ht_traject/ht_dbh"

module CICTL
  class CollectionMap
    def to_yaml
      collection_map.to_yaml
    end

    private

    def collection_map
      @collection_map ||= begin
        db = HathiTrust::DBH::DB
        sql = <<~SQL
          select collection, coalesce(mapto_name,name) name
          from ht_institutions i join ht_collections c
          on c.original_from_inst_id = i.inst_id
        SQL
        ccof = {}
        db[sql].order(:collection).each do |h|
          ccof[h[:collection].downcase] = h[:name]
        end
        ccof
      end
    end
  end
end
