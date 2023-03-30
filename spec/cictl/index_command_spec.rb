require "spec_helper"

RSpec.describe CICTL::IndexCommand do
  before(:all) do
    CICTL::SolrClient.new.empty!.commit!
  end

  after(:each) do
    CICTL::SolrClient.new.empty!.commit!
  end

  describe "#index all" do
    it "indexes 27 records" do
      CICTL::CICTL.start(["index", "all", "--log", "TEST_LOG.txt", "--today", "20230103", "--no-wait"])
      expect(solr_count).to eq 27
    end
  end

  describe "#index date" do
    it "indexes 10 records" do
      CICTL::CICTL.start(["index", "date", "20230103", "--log", test_log])
      expect(solr_count).to eq 8
    end
  end

  describe "#index file" do
    context "with no additional parameters" do
      it "indexes 10 records" do
        file = File.join(ENV["DDIR"], "zephir_upd_20230103.json.gz")
        CICTL::CICTL.start(["index", "file", file, "--log", test_log])
        expect(solr_count).to eq 8
      end
    end

    context "with an explicit reader" do
      context "that exists" do
        it "indexes 10 records" do
          file = File.join(ENV["DDIR"], "zephir_upd_20230103.json.gz")
          CICTL::CICTL.start(["index", "file", file, "--log", test_log, "--reader", "readers/jsonl"])
          expect(solr_count).to eq 8
        end
      end

      context "that does not exist" do
        it "fails" do
          file = File.join(ENV["DDIR"], "zephir_upd_20230223.json.gz")
          expect {
            CICTL::CICTL.start(["index", "file", file, "--log", "TEST_LOG.txt", "--reader", "no_such_reader"])
          }.to raise_error(CICTL::CICTLError)
        end
      end
    end

    context "with an explicit writer" do
      context "that exists" do
        it "indexes 10 records" do
          file = File.join(ENV["DDIR"], "zephir_upd_20230103.json.gz")
          CICTL::CICTL.start(["index", "file", file, "--log", test_log, "--writer", "writers/localhost"])
          expect(solr_count).to eq 8
        end
      end

      context "that does not exist" do
        it "fails" do
          file = File.join(ENV["DDIR"], "zephir_upd_20230103.json.gz")
          expect {
            CICTL::CICTL.start(["index", "file", file, "--log", test_log, "--writer", "no_such_writer"])
          }.to raise_error(CICTL::CICTLError)
        end
      end
    end
  end

  describe "#index today" do
    it "indexes 0 records" do
      CICTL::CICTL.start(["index", "today", "--log", test_log])
      expect(solr_count).to eq 0
    end
  end
end
