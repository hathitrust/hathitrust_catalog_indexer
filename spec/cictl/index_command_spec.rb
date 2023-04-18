# frozen_string_literal: true

require "spec_helper"

RSpec.describe CICTL::IndexCommand do
  before(:each) do
    CICTL::SolrClient.new.empty!.commit!
    ENV["CICTL_ZEPHIR_FILE_TEMPLATE_PREFIX"] = "sample"
  end

  after(:each) do
    CICTL::SolrClient.new.empty!.commit!
    ENV.delete "CICTL_ZEPHIR_FILE_TEMPLATE_PREFIX"
  end

  describe "#index all" do
    it "indexes all example records" do
      # Make a fake delete entry for a bogus id
      bogus_delete = "000000000"
      CICTL::SolrClient.new.set_deleted [bogus_delete]
      CICTL::Command.start(["index", "all", "--no-wait", "--log", test_log])
      expect(solr_count).to eq CICTL::Examples.all_ids.count + 1
      expect(solr_deleted_count).to be > 0
      expect(solr_ids("deleted:true")).to include(bogus_delete)
    end
  end

  describe "#index date" do
    it "indexes full records and deleted record from example date" do
      examples = CICTL::Examples.for_date("20230103")
      CICTL::Command.start(["index", "date", "20230103", "--log", test_log])
      expect(solr_count).to eq examples.map { |ex| ex[:ids] }.flatten.uniq.count
    end
  end

  describe "#index file" do
    context "with no additional parameters" do
      it "indexes full records and no deletes from example file" do
        example = CICTL::Examples.for_date("20230103", type: :upd).first
        file = File.join(ENV["DDIR"], example[:file])
        CICTL::Command.start(["index", "file", file, "--log", test_log])
        expect(solr_count).to eq example[:ids].count
      end
    end

    context "with an explicit reader" do
      context "that exists" do
        it "indexes full records and no deletes from example file" do
          example = CICTL::Examples.for_date("20230103", type: :upd).first
          file = File.join(ENV["DDIR"], example[:file])
          CICTL::Command.start(["index", "file", file, "--reader", "readers/jsonl", "--log", test_log])
          expect(solr_count).to eq example[:ids].count
        end
      end

      context "that does not exist" do
        it "fails" do
          file = File.join(ENV["DDIR"], "sample_upd_20230223.json.gz")
          expect {
            CICTL::Command.start(["index", "file", file, "--reader", "no_such_reader", "--log", test_log])
          }.to raise_error(CICTL::CICTLError)
        end
      end
    end

    context "with an explicit writer" do
      context "that exists" do
        it "indexes full records and no deletes from example file" do
          example = CICTL::Examples.for_date("20230103", type: :upd).first
          file = File.join(ENV["DDIR"], example[:file])
          CICTL::Command.start(["index", "file", file, "--writer", "writers/localhost", "--log", test_log])
          expect(solr_count).to eq example[:ids].count
        end
      end

      context "that does not exist" do
        it "fails" do
          file = File.join(ENV["DDIR"], "sample_upd_20230103.json.gz")
          expect {
            CICTL::Command.start(["index", "file", file, "--writer", "no_such_writer", "--log", test_log])
          }.to raise_error(CICTL::CICTLError)
        end
      end
    end
  end

  describe "#index today" do
    it "indexes 0 records" do
      CICTL::Command.start(["index", "today", "--log", test_log])
      expect(solr_count).to eq 0
    end
  end
end
