# frozen_string_literal: true

require_relative "../services"

module CICTL
  class CollectionMap
    def to_yaml
      collection_map.to_yaml
    end

    private

    def collection_map
      @collection_map ||= begin
        sql = <<~SQL
          select collection, coalesce(mapto_name,name) name
          from ht_institutions i join ht_collections c
          on c.original_from_inst_id = i.inst_id
        SQL
        ccof = {}
        HathiTrust::Services[:db][sql].order(:collection).each do |h|
          ccof[h[:collection].downcase] = h[:name]
        end
        ccof
      end
    end
  end
end
