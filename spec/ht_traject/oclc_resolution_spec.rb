# frozen_string_literal: true

require "spec_helper"

RSpec.describe HathiTrust::OCLCResolution do
  # A sample of data from the current table
  let(:oclc_sample_data) {
    [
      # variant, canonical
      [1429614234, 1431896995],
      [1266390115, 1431896866],
      [1424497674, 1431202652],
      [1430755151, 1431202613],
      [1430658683, 1431202613],
      [1430755662, 1431202593],
      [1430661200, 1431202593],
      [1431033788, 1431202557],
      [1430755166, 1431202510],
      [1430755684, 1431202283]
    ]
  }

  around(:each) do |example|
    HathiTrust::Services[:db][:oclc_concordance].truncate
    HathiTrust::Services[:db][:oclc_concordance].import([:variant, :canonical], oclc_sample_data)
    example.run
  end

  describe ".query" do
    it "returns a query" do
      expect(described_class.query).not_to be_nil
    end
  end
  
  describe ".all_resolved_oclcs" do
    it "returns empty Array for empty OCLC list" do
      expect(described_class.all_resolved_oclcs([])).to eq([])
    end

    it "returns all OCLCs for noncanonical OCLCs" do
      expect(described_class.all_resolved_oclcs([1429614234]).sort).to eq(["1429614234", "1431896995"].sort)
    end

    it "returns all OCLCs for canonical OCLCs" do
      expect(described_class.all_resolved_oclcs([1431896995]).sort).to eq(["1429614234", "1431896995"].sort)
    end
    
    it "preserves OCLCs not found in table" do
      expect(described_class.all_resolved_oclcs([1])).to eq(["1"])
    end
  end
end
