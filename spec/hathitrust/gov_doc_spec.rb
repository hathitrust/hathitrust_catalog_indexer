# frozen_string_literal: true

require "spec_helper"
require "hathitrust/catalog_record"
#require "json"
#require "bib_record"

RSpec.describe HathiTrust::GovDoc do
  let(:rec) { HathiTrust::CatalogRecord.from_ndj(bib_fixture("bib_rec.json")) }

  def bib_fixture(name)
    fixture(File.join("catalog_record", name))
  end

  def from_fixture(name)
    catalog_record = HathiTrust::CatalogRecord.from_ndj(bib_fixture(name))
    described_class.new(catalog_record: catalog_record)
  end

  describe "#excluded_oclc_number?" do
    it "is an exception if it has a reject oclc number " do
      allow(rec).to receive(:oclcs).and_return([RejectedList.oclcs.first])
      gd = described_class.new(catalog_record: rec)
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
