# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe HathiTrust::GovDoc do
  def bib_fixture(name)
    fixture(File.join("catalog_record", name))
  end

  def from_fixture(name, oclcs = [])
    json = File.read(bib_fixture(name))
    marc_record = MARC::Record.new_from_hash JSON.parse(json, symbolize_keys: false)
    described_class.new(marc_record, oclcs)
  end

  describe "#gov_doc?" do
    it "returns `false` with sample document" do
      json = File.read(fixture("sample_record.json"))
      marc_record = MARC::Record.new_from_hash JSON.parse(json, symbolize_keys: false)
      gd = described_class.new(marc_record, [])
      expect(gd.gov_doc?).to be false
    end
  end

  describe "#excluded_oclc_number?" do
    it "is an exception if it has a rejected oclc number" do
      gd = from_fixture("bib_rec.json", [RejectedList.oclcs.first])
      expect(gd.excluded_oclc_number?).to be true
      expect(gd.exception_to_rule?).to be true
    end
  end

  describe "#nist_nsrds?" do
    it "detects an NSRDS record" do
      nsrds_rec = from_fixture("nsrds_bib_rec.json")
      expect(nsrds_rec.nist_nsrds?).to be true
      expect(nsrds_rec.exception_to_rule?).to be true
    end
  end

  describe "#ntis?" do
    it "detects an NTIS record" do
      ntis_rec = from_fixture("ntis_bib_rec.json")
      expect(ntis_rec.ntis?).to be true
      expect(ntis_rec.exception_to_rule?).to be true
    end
  end

  describe "#armed_forces_communications_association?" do
    it "detects an Armed Forces Communications Association record" do
      afca_rec = from_fixture("afca_bib_rec.json")
      expect(afca_rec.armed_forces_communications_association?).to be true
      expect(afca_rec.exception_to_rule?).to be true
    end
  end

  describe "#national_research_council?" do
    it "detects an NRC record" do
      nrc_rec = from_fixture("nrc_bib_rec.json")
      expect(nrc_rec.national_research_council?).to be true
      expect(nrc_rec.exception_to_rule?).to be true
    end
  end

  describe "#smithsonian?" do
    it "detects a smithsonian record" do
      smith_rec = from_fixture("smithsonian_bib_rec.json")
      expect(smith_rec.smithsonian?).to be true
      expect(smith_rec.exception_to_rule?).to be true
    end
  end

  describe "#national_gallery_of_art?" do
    it "detects an NGOA record" do
      ngoa_rec = from_fixture("ngoa_bib_rec.json")
      expect(ngoa_rec.national_gallery_of_art?).to be true
      expect(ngoa_rec.exception_to_rule?).to be true
    end
  end

  describe "#federal_reserve?" do
    it "detects a Federal Reserve record" do
      fr_rec = from_fixture("federal_reserve_bib_rec.json")
      expect(fr_rec.federal_reserve?).to be true
      expect(fr_rec.exception_to_rule?).to be true
    end
  end
end
