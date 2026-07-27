# frozen_string_literal: true
require "filter"
require "filter/rejected_list"

module HathiTrust
  class GovDoc
    attr_reader :catalog_record

    def initialize(catalog_record:)
      @catalog_record = catalog_record
    end

    def marc_record
      @marc_record ||= catalog_record.marc_record
    end

    def gov_doc?
      marc_record["008"].value[28] == "f" && catalog_record.pub_place_code[2] == "u" && !exception_to_rule?
    end

    def exception_to_rule?
      excluded_oclc_number? ||
        nist_nsrds? ||
        ntis? ||
        armed_forces_communications_association? ||
        national_research_council? ||
        smithsonian? ||
        national_gallery_of_art? ||
        federal_reserve?
    end

    def excluded_oclc_number?
      catalog_record.oclcs&.any? { |o| RejectedList.oclcs.include? o.to_i }
    end

    def nist_nsrds?
      ::Traject::MarcExtractor.cached("400:410:411:440:490:800:810:811:830")
        .extract(marc_record).any?(/(nsrds|national standard reference data series)/i)
    end

    def ntis?
      ::Traject::MarcExtractor.cached("260:264")
        .extract(marc_record).any?(/ntis|national technical information service/i)
    end

    def armed_forces_communications_association?
      ::Traject::MarcExtractor.cached("260:264:110:710")
        #FIXME: doesn't this match 'Armed Forces Communications Communications and Electronics Association'?
        .extract(marc_record).any?(/armed forces communications (association|communications and electronics association)/i)
    end

    def national_research_council?
      auth = ::Traject::MarcExtractor.cached("260:264:110:710").extract(marc_record)
      auth.any?(/national research council/i) && auth.none?(/canada/i)
    end

    def smithsonian?
      ::Traject::MarcExtractor.cached("260:264:110:130:710")
        .extract(marc_record).any?(/smithsonian/i)
    end

    def national_gallery_of_art?
      ::Traject::MarcExtractor.cached("260:264:110:710")
        .extract(marc_record).any?(/national gallery of art/i)
    end

    def federal_reserve?
      ::Traject::MarcExtractor.cached("100:110:111:700:710:711")
        .extract(marc_record).any?(/federal reserve/i)
    end
  end
end

