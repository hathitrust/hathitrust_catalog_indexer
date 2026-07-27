# frozen_string_literal: true

require "json"
require "marc"
require "traject/macros/marc21_semantics"

require "spec_helper"
require "hathitrust/gov_doc"
require "hathitrust/record_date"

module HathiTrust
  # A wrapper around MARC::Record which exposes uniquely HathiTrust derivative data,
  # in particular location, federal government document status, and perhapsitem data.
  # TODO: consider making this a SimpleDelegator?
  class CatalogRecord
    attr_reader :marc_record

    def self.from_ndj(path)
      json = File.read(path)
      marc_record = MARC::Record.new_from_hash JSON.parse(json, symbolize_keys: false)
      new(marc_record: marc_record)
    end

    def initialize(marc_record:)
      @marc_record = marc_record
    end

    # HathiTrust::RecordDate object
    # whence one can query `date` and `raw_date`
    def record_date
      @record_date ||= RecordDate.new(catalog_record: self)
    end

    # Returns true if HathiTrust::GovDoc identifies 'f' in record 008,
    # and the publisher is not in the exceptions list,
    # and if none of the OCLCs is in our rejected list.
    def gov_doc?
      @gov_doc ||= GovDoc.new(catalog_record: self).gov_doc?
    end

    # A sorted array of String
    def oclcs
      @oclcs ||= ::Traject::MarcExtractor.cached("035a", :separator => nil)
        .extract(marc_record)
        .collect! do |o|
          ::Traject::Macros::Marc21Semantics.oclcnum_extract(o)
        end
        .compact
        .sort
    end

    # Returns the 008 place of publication as a lowercase three-character code
    # with non-alphabetic material removed.
    # Anomalous Puerto Rico "pr*" and US "us*" values are normalized.
    # Default "unknown" or "non-normalizable" value is "   " (three spaces).
    def pub_place_code(field_008: marc_record["008"])
      code = field_008&.value&.slice(15..17)&.downcase || ""
      code = code.gsub(/[?|^]/, " ")
      code = "   " unless /^[a-z ]{2,3}/.match?(code)
      code = "pru" if /^pr/.match?(code)
      code = "xxu" if /^us/.match?(code)
      code
    end
  end
end
