# frozen_string_literal: true

require "spec_helper"
require "hathitrust/catalog_record"

RSpec.describe HathiTrust::CatalogRecord do
  let(:cr) { from_fixture("bib_rec.json") }

  #FIXME: rename and move to spec_helper
  def bib_fixture(name)
    fixture(File.join("catalog_record", name))
  end

  def from_fixture(name)
    marc_in_json = File.read(bib_fixture(name))
    marc_record = MARC::Record.new_from_hash JSON.parse(marc_in_json, symbolize_keys: false)
    described_class.new(marc_record: marc_record)
  end

  describe ".new" do
    it "returns #{described_class}" do
      expect(cr).to be_a(described_class)
    end
  end

  describe "#record_date" do
    it "returns a `HathiTrust::RecordDate` object" do
      expect(cr.record_date).to be_a(HathiTrust::RecordDate)
    end
  end

  describe "oclcs" do
    it "returns multiple items" do
      expect(cr.oclcs.count.positive?).to be(true)
    end

    it "returns stringified OCLCs" do
      expect(cr.oclcs.first).to be_a(String)
    end
  end
end
