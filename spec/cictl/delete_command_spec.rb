# frozen_string_literal: true

require "spec_helper"

RSpec.describe CICTL::DeleteCommand do
  around(:each) do |example|
    with_test_environment do |tmpdir|
      example.run
    end
  end

  describe "#delete all" do
    it "deletes all records" do
      example = CICTL::Examples.for_date("20230103", type: :upd).first
      file = File.join(HathiTrust::Services[:data_directory], example[:file])
      CICTL::Commands.start(["index", "file", file, "--quiet"])
      expect(solr_count).to be > 0
      CICTL::Commands.start(["delete", "all", "--quiet"])
      expect(solr_count).to eq 0
    end
  end

  describe "#delete file" do
    it "deletes 1 record" do
      upd_example = CICTL::Examples.for_date("20230102", type: :upd).first
      file = File.join(HathiTrust::Services[:data_directory], upd_example[:file])
      CICTL::Commands.start(["index", "file", file, "--quiet"])
      expect(solr_count).to eq upd_example[:ids].count
      expect(solr_deleted_count).to eq 0
      delete_example = CICTL::Examples.for_date("20230102", type: :delete).first
      file = File.join(HathiTrust::Services[:data_directory], delete_example[:file])
      CICTL::Commands.start(["delete", "file", file, "--quiet"])
      expect(solr_count).to eq (upd_example[:ids] + delete_example[:ids]).uniq.count
      expect(solr_deleted_count).to eq delete_example[:ids].count
    end

    it "handles empty file" do
      file = File.join(HathiTrust::Services[:data_directory], CICTL::Examples.empty_delete_file)
      CICTL::Commands.start(["delete", "file", file, "--quiet"])
    end

    it "handles file with spaces-only line" do
      file = File.join(HathiTrust::Services[:data_directory], CICTL::Examples.blank_line_delete_file)
      CICTL::Commands.start(["delete", "file", file, "--quiet"])
    end

    it "errors on noisy file" do
      file = File.join(HathiTrust::Services[:data_directory], CICTL::Examples.noisy_delete_file)
      expect { CICTL::Commands.start(["delete", "file", file, "--quiet"]) }.to raise_error(RSolr::Error::Http)
    end
  end
end
