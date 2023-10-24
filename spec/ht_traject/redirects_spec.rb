# frozen_string_literal: true

require "spec_helper"

RSpec.describe HathiTrust::Redirects do
  # The example file contains the line "000004165	006215998" (old, new) so
  # redirects["006215998"] -> ["000004165"]
  let(:sample_old_cid) { "000004165" }
  let(:sample_new_cid) { "006215998" }

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
