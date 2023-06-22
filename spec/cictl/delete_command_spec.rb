# frozen_string_literal: true

require "spec_helper"

RSpec.describe CICTL::DeleteCommand do
  before(:each) do
    CICTL::SolrClient.new.empty!.commit!
    ENV["CICTL_ZEPHIR_FILE_TEMPLATE_PREFIX"] = "sample"
  end

  after(:each) do
    CICTL::SolrClient.new.empty!.commit!
    ENV.delete "CICTL_ZEPHIR_FILE_TEMPLATE_PREFIX"
  end

  describe "#delete all" do
    it "deletes all records" do
      example = CICTL::Examples.for_date("20230103", type: :upd).first
      file = File.join(HathiTrust::Services["data_directory"], example[:file])
      CICTL::Command.start(["index", "file", file, "--log", test_log])
      expect(solr_count).to be > 0
      CICTL::Command.start(["delete", "all", "--log", test_log])
      expect(solr_count).to eq 0
    end
  end

  describe "#delete file" do
    it "deletes 1 record" do
      upd_example = CICTL::Examples.for_date("20230102", type: :upd).first
      file = File.join(HathiTrust::Services["data_directory"], upd_example[:file])
      CICTL::Command.start(["index", "file", file, "--log", test_log])
      expect(solr_count).to eq upd_example[:ids].count
      expect(solr_deleted_count).to eq 0
      delete_example = CICTL::Examples.for_date("20230102", type: :delete).first
      file = File.join(HathiTrust::Services["data_directory"], delete_example[:file])
      CICTL::Command.start(["delete", "file", file, "--log", test_log])
      expect(solr_count).to eq (upd_example[:ids] + delete_example[:ids]).uniq.count
      expect(solr_deleted_count).to eq delete_example[:ids].count
    end

    it "handles empty file" do
      file = File.join(HathiTrust::Services["data_directory"], CICTL::Examples.empty_delete_file)
      CICTL::Command.start(["delete", "file", file, "--log", test_log])
    end
  end
end
