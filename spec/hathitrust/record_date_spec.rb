# frozen_string_literal: true

require "spec_helper"
require "hathitrust/catalog_record"
require "hathitrust/record_date"
require "marc"

RSpec.describe HathiTrust::RecordDate do
  let(:marc) { MARC::Record.new }
  #let(:rec) { HathiTrust::CatalogRecord.from_ndj(bib_fixture("bib_rec.json")) }

  def bib_fixture(name)
    fixture(File.join("catalog_record", name))
  end

  # Create the MARC and Catalog records holding a 008 or 260$c
  def with_data(field_008: nil, field_260: nil)
    marc = MARC::Record.new
    if field_008
      marc.append(
        MARC::ControlField.new("008", field_008)
      )
    end
    if field_260
      marc.append(
        MARC::DataField.new("260", "0", "0", MARC::Subfield.new("c", field_260))
      )
    end
    catalog_record = HathiTrust::CatalogRecord.new(marc_record: marc)
    described_class.new(catalog_record: catalog_record)
  end

  describe ".compute_date_range" do
    it "converts pre-1500 dates to 'Pre-1500'" do
      expect(described_class.compute_date_range(1499)).to eq("Pre-1500")
      expect(described_class.compute_date_range("1499")).to eq("Pre-1500")
    end

    it "converts 15** thru 18** dates to century range" do
      {
        1500 => "1500-1599",
        1600 => "1600-1699",
        1700 => "1700-1799",
        1800 => "1800-1899"
      }.each do |input, output|
        expect(described_class.compute_date_range(input)).to eq(output)
        expect(described_class.compute_date_range(input.to_s)).to eq(output)
      end
    end

    it "converts 1801+ dates to decade range" do
      {
        1910 => "1910-1919",
        1990 => "1990-1999",
        2000 => "2000-2009",
        2010 => "2010-2019",
        2025 => "2020-2029",
        2100 => "2100-2109"
      }.each do |input, output|
        expect(described_class.compute_date_range(input)).to eq(output)
        expect(described_class.compute_date_range(input.to_s)).to eq(output)
      end
    end

    it "converts post-2100 to nil" do
      expect(described_class.compute_date_range(2101)).to eq(nil)
      expect(described_class.compute_date_range("2101")).to eq(nil)
    end

    it "returns `nil` for `nil`" do
      expect(described_class.compute_date_range(nil)).to eq(nil)
    end
  end

  describe ".ordinalize_incomplete_year" do
    it "uses 'th' for '1n' expressions" do
      expect(described_class.ordinalize_incomplete_year('11')).to eq("11th")
    end

    it "uses 'st' for 'd?1' expressions" do
      expect(described_class.ordinalize_incomplete_year('21')).to eq("21st")
    end
    
    it "uses 'nd' for 'd?2' expressions" do
      expect(described_class.ordinalize_incomplete_year('22')).to eq("22nd")
    end
    
    it "uses 'rd' for 'd?3' expressions" do
      expect(described_class.ordinalize_incomplete_year('23')).to eq("23rd")
    end
    
    it "uses 'th' for everything else" do
      expect(described_class.ordinalize_incomplete_year('23')).to eq("23rd")
    end
  end

  describe "#date" do
    it "translates 'u' (unknown) values to 0" do
      expect(with_data(field_008: "123456s19uu    ").date).to eq("1900")
    end

    it "does nothing with nil values" do
      expect(with_data.date).to eq(nil)
    end
  end

  describe "display_dates" do
    it "returns `nil` if there is no date" do
      expect(with_data.display_dates).to eq(nil)
    end

    it "returns 008 date if it is complete" do
      expect(with_data(field_008: "123456s1900    ").display_dates).to eq(["1900"])
    end

    it "returns 'in decade' value if final digit is unknown" do
      expect(with_data(field_008: "123456s190u    ").display_dates).to eq(["in the 1900s"])
    end

    it "returns 'in century' value if final two digits are unknown" do
      expect(with_data(field_008: "123456s19uu    ").display_dates).to eq(["in the 20th century"])
    end

    it "returns range value for 1uuu" do
      expect(with_data(field_008: "123456s1uuu    ").display_dates).to eq(["between 1000 and 1999"])
    end

    it "returns range value for 2uuu" do
      expect(with_data(field_008: "123456s2uuu    ").display_dates).to eq(["between 2000 and 2999"])
    end
  end

  describe "#raw_date" do
    context "with no 008 and no 260$c" do
      it "returns nil" do
        expect(with_data.raw_date).to eq(nil)
      end
    end

    context "with 008" do
      it "returns a value" do
        expect(with_data(field_008: "123456s1900    ").raw_date).to eq("1900")
      end

      it "returns nil if truncated" do
        expect(with_data(field_008: "123456").raw_date).to eq(nil)
      end

      it "returns nil if date type is 'b' (BC date)" do
        expect(with_data(field_008: "123456b####    ").raw_date).to eq(nil)
      end

      it "returns nil if date type is 'n' (unknown)" do
        expect(with_data(field_008: "123456nuuuu    ").raw_date).to eq(nil)
      end
    end

    context "with 260$c" do
      it "returns a year if found" do
        expect(with_data(field_260: "1900.").raw_date).to eq("1900")
      end

      it "returns nil if no four-digit value" do
        expect(with_data(field_260: "gibberish").raw_date).to eq(nil)
      end
    end
  end
end
