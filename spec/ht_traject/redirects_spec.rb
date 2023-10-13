# frozen_string_literal: true

require "spec_helper"

RSpec.describe HathiTrust::Redirects do
  before do
    @real_data_directory = HathiTrust::Services[:data_directory]
  end

  let(:real_file) { File.join(@real_data_directory, CICTL::Examples.redirects_file) }
  let(:no_file) { File.join(@real_data_directory, "no_such_redirects_file.txt.gz") }
  # The example file contains the line "000004165	006215998" (old, new) so
  # redirects["006215998"] -> ["000004165"]
  let(:sample_old_cid) { "000004165" }
  let(:sample_new_cid) { "006215998" }
  let(:services_double) { class_double("HathiTrust::Services").as_stubbed_const }

  describe "#exist?" do
    context "with a real file" do
      it "returns true" do
        allow(services_double).to receive(:[]).with(:redirect_file).and_return(real_file)
        expect(described_class.new.exist?).to eq true
      end
    end

    context "with a nonexistent file" do
      it "returns false" do
        allow(services_double).to receive(:[]).with(:redirect_file).and_return(no_file)
        expect(described_class.new.exist?).to eq false
      end
    end
  end

  describe "#old_ids_for" do
    context "with a real file" do
      it "returns the old CID" do
        allow(services_double).to receive(:[]).with(:redirect_file).and_return(real_file)
        expect(described_class.new.old_ids_for(sample_new_cid)).to eq([sample_old_cid])
      end
    end

    context "with a nonexistent file" do
      it "raises error" do
        allow(services_double).to receive(:[]).with(:redirect_file).and_return(no_file)
        expect { described_class.new.old_ids_for(sample_new_cid) }.to raise_error(Errno::ENOENT)
      end
    end
  end
end
