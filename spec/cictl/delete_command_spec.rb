require "spec_helper"

RSpec.describe CICTL::IndexCommand do
  before(:all) do
    CICTL::SolrClient.new.empty!.commit!
  end

  before(:each) do
    ENV["CICTL_ZEPHIR_FILE_TEMPLATE_PREFIX"] = "sample"
  end

  after(:each) do
    CICTL::SolrClient.new.empty!.commit!
    ENV.delete "CICTL_ZEPHIR_FILE_TEMPLATE_PREFIX"
  end

  describe "#delete all" do
    it "deletes all records" do
      CICTL::CICTL.start(["index", "date", "20230103", "--log", "TEST_LOG.txt"])
      expect(solr_count).to eq 8
      CICTL::CICTL.start(["delete", "all"])
      expect(solr_count).to eq 0
    end
  end

  describe "#delete file" do
    it "deletes 1 record" do
      CICTL::CICTL.start(["index", "date", "20230102", "--log", "TEST_LOG.txt"])
      expect(solr_count).to eq 4
      file = File.join(ENV["DDIR"], "sample_upd_20230103_delete.txt.gz")
      CICTL::CICTL.start(["delete", "file", file, "--log", "TEST_LOG.txt"])
      expect(solr_count).to eq 3
    end
  end
end
