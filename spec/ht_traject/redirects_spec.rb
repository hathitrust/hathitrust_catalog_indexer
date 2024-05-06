# frozen_string_literal: true

require "spec_helper"

RSpec.describe HathiTrust::Redirects do
  # The example file contains the line "000004165	006215998" (old, new) so
  # redirects["006215998"] -> ["000004165"]
  let(:sample_old_cid) { "000004165" }
  let(:sample_new_cid) { "006215998" }

  describe ".redirects_file_name" do
    it "generates the appropriately dated redirects file" do
      expect(described_class.redirects_file_name(date: Date.parse("2024-01-01")))
        .to eq("redirects_202401.txt.gz")
    end
  end

  describe ".default_redirects_file" do
    context "with current month's file" do
      it "uses the existing file" do
        Dir.mktmpdir do |tmpdir|
          current_file = File.join(tmpdir, described_class.redirects_file_name)
          `touch #{current_file}`
          expect(described_class.default_redirects_file(directory: tmpdir))
            .to eq(current_file)
        end
      end
    end

    context "without current month's file" do
      it "uses last month's file" do
        Dir.mktmpdir do |tmpdir|
          last_file = File.join(tmpdir, described_class.redirects_file_name(date: Date.today << 1))
          `touch #{last_file}`
          expect(described_class.default_redirects_file(directory: tmpdir))
            .to eq(last_file)
        end
      end
    end
  end

  describe "#old_ids_for" do
    context "with a real file" do
      override_service(:redirect_file) do
        File.join(HathiTrust::Services[:data_directory], CICTL::Examples.redirects_file)
      end

      it "returns the old CID" do
        expect(described_class.new.old_ids_for(sample_new_cid)).to eq([sample_old_cid])
      end
    end

    context "with a nonexistent file" do
      override_service(:redirect_file) do
        File.join(HathiTrust::Services[:data_directory], "no_such_redirects_file.txt.gz")
      end

      it "raises error" do
        expect { described_class.new.old_ids_for(sample_new_cid) }.to raise_error(Errno::ENOENT)
      end
    end
  end
end
