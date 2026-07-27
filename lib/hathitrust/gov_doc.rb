# frozen_string_literal: true

require "filter"
require "filter/rejected_list"

module HathiTrust
  class GovDoc
    attr_reader :marc_record, :oclcs

    NIST_NSRDS_RE = /(nsrds|national standard reference data series)/i
    NTIS_RE = /ntis|national technical information service/i
    # Note: RE fixed from hathifiles version and experimental HCI branch -- need to backport
    AFCA_RE = /armed forces communications (and electronics )?association/i
    NATIONAL_RESEARCH_COUNCIL_RE = /national research council/i
    SMITHSONIAN_RE = /smithsonian/i
    NATIONAL_GALLERY_OF_ART_RE = /national gallery of art/i
    FEDERAL_RESERVE_RE = /federal reserve/i

    def initialize(marc_record, oclcs)
      @marc_record = marc_record
      @oclcs = oclcs || []
    end

    def gov_doc?
      marc_record["008"].value[28] == "f" && pub_place_code[2] == "u" && !exception_to_rule?
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
      oclcs&.any? { |o| RejectedList.oclcs.include? o.to_i }
    end

    def nist_nsrds?
      cached("400:410:411:440:490:800:810:811:830").extract(marc_record).any?(NIST_NSRDS_RE)
    end

    def ntis?
      cached("260:264").extract(marc_record).any?(NTIS_RE)
    end

    def armed_forces_communications_association?
      cached("260:264:110:710").extract(marc_record).any?(AFCA_RE)
    end

    def national_research_council?
      auth = cached("260:264:110:710").extract(marc_record)
      auth.any?(NATIONAL_RESEARCH_COUNCIL_RE) && auth.none?(/canada/i)
    end

    def smithsonian?
      cached("260:264:110:130:710").extract(marc_record).any?(SMITHSONIAN_RE)
    end

    def national_gallery_of_art?
      cached("260:264:110:710").extract(marc_record).any?(NATIONAL_GALLERY_OF_ART_RE)
    end

    def federal_reserve?
      cached("100:110:111:700:710:711").extract(marc_record).any?(FEDERAL_RESERVE_RE)
    end

    private

    # Just a shortcut
    def cached(fields)
      ::Traject::MarcExtractor.cached(fields)
    end

    # Taken mostly verbatim from hathifiles `PlaceOfPublication` class.
    # TODO: this will move to a host object with a more complete place of publication functionality.
    def pub_place_code
      code = marc_record["008"]&.value&.slice(15..17)&.downcase || ""
      code = code.gsub(/[?|^]/, " ")
      code = "   " unless /^[a-z ]{2,3}/.match?(code)
      code = "pru" if /^pr/.match?(code)
      code = "xxu" if /^us/.match?(code)
      code
    end
  end
end

