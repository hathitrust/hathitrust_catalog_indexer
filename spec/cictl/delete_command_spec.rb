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
      file = File.join(ENV["DDIR"], example[:file])
      CICTL::CICTL.start(["index", "file", file, "--log", test_log])
      expect(solr_count).to be > 0
      CICTL::CICTL.start(["delete", "all"])
      expect(solr_count).to eq 0
    end
  end

  describe "#delete file" do
    it "deletes 1 record" do
      upd_example = CICTL::Examples.for_date("20230102", type: :upd).first
      file = File.join(ENV["DDIR"], upd_example[:file])
      CICTL::CICTL.start(["index", "file", file, "--log", test_log])
      expect(solr_count).to eq upd_example[:ids].count
      expect(solr_deleted_count).to eq 0
      delete_example = CICTL::Examples.for_date("20230102", type: :delete).first
      file = File.join(ENV["DDIR"], delete_example[:file])
      CICTL::CICTL.start(["delete", "file", file, "--log", test_log])
      expect(solr_count).to eq (upd_example[:ids] + delete_example[:ids]).uniq.count
      expect(solr_deleted_count).to eq delete_example[:ids].count
    end
  end
end
