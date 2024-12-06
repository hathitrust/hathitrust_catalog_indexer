# frozen_string_literal: true

require_relative "../services"

module CICTL
  class CollectionMap
    # The main purpose of this class is to provide a Traject::TranslationMap.
    # Reads from YAML file or database depending on whether we're using the database
    # (which in almost all cases we will be).
    def to_translation_map(no_db: HathiTrust::Services[:no_db?])
      Traject::TranslationMap.new(no_db ? "ht/collection_code_to_original_from" : collection_map)
    end

    private

    # Returns a Hash that can, if necessary, be sent #.to_yaml
    # to update the `ht/collection_code_to_original_from.yaml` file.
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
