require "spec_helper"

RSpec.describe CICTL::SolrClient do
  describe "#to_s" do
    it "it incorporates SOLR_URL into stringified form" do
      expect(described_class.new.to_s).to match(ENV["SOLR_URL"])
    end
  end

  describe "#commit!" do
    it "calls the post method with the correct arguments" do
      mock = double("HTTPX")
      expect(mock).to receive(:post).with(instance_of(String),
        hash_including(json: {"commit" => {}}))
      described_class.new(mock).commit!
    end
  end

  describe "#empty!" do
    it "calls the post method with the correct arguments" do
      mock = double("HTTPX")
      expect(mock).to receive(:post).with(instance_of(String),
        hash_including(json: {"delete" => {"query" => "deleted:(NOT true)"}}))
      described_class.new(mock).empty!
    end
  end
end
