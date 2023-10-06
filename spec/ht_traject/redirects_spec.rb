# frozen_string_literal: true

require "spec_helper"

# The example file contains the line "000004165	006215998" (old, new) so
# redirects["006215998"] -> ["000004165"]
SAMPLE_OLD_CID = "000004165"
SAMPLE_NEW_CID = "006215998"

RSpec.describe HathiTrust::Redirects do
  let(:real_file) { File.join(HathiTrust::Services["data_directory"], CICTL::Examples.redirects_file) }
  let(:no_file) { File.join(HathiTrust::Services["data_directory"], "no_such_redirects_file.txt.gz") }

  describe "#initialize" do
    it "creates a HathiTrust::Redirects object" do
      expect(described_class.new).to be_kind_of(described_class)
    end
  end

  describe "#exist?" do
    context "with a real file" do
      it "returns true" do
        expect(described_class.new(real_file).exist?).to eq true
      end
    end

    context "with a nonexistent file" do
      it "returns false" do
        expect(described_class.new(no_file).exist?).to eq false
      end
    end
  end

  describe "#old_ids_for" do
    context "with a real file" do
      it "returns the old CID" do
        expect(described_class.new(real_file).old_ids_for(SAMPLE_NEW_CID)).to eq([SAMPLE_OLD_CID])
      end
    end

    context "with a nonexistent file" do
      it "returns empty array" do
        expect(described_class.new(no_file).old_ids_for(SAMPLE_NEW_CID)).to eq([])
      end
    end
  end

  describe "#[]" do
    context "with a real file" do
      it "returns the old CID" do
        expect(described_class.new(real_file)[SAMPLE_NEW_CID]).to eq([SAMPLE_OLD_CID])
      end
    end

    context "with a nonexistent file" do
      it "returns empty array" do
        expect(described_class.new(no_file)[SAMPLE_NEW_CID]).to eq([])
      end
    end
  end
end
