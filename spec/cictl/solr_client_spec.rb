# frozen_string_literal: true

require "spec_helper"

RSpec.describe CICTL::SolrClient do
  describe "#to_s" do
    it "it incorporates SOLR_URL into stringified form" do
      expect(described_class.new.to_s).to match(ENV["SOLR_URL"])
    end
  end

  describe "#commit!" do
    it "calls the commit method with no arguments" do
      mock = double("RSolr")
      expect(mock).to receive(:commit).with(no_args)
      described_class.new(mock).commit!
    end
  end

  describe "#count" do
    def count
      mock = double("RSolr")
      expect(mock).to receive(:get).with(instance_of(String),
        hash_including(q: ":", wt: "ruby", rows: 1))
      described_class.new(mock).count
    end
  end

  describe "#empty!" do
    it "calls the delete_by_query method with the correct arguments" do
      mock = double("RSolr")
      expect(mock).to receive(:delete_by_query).with(instance_of(String))
      described_class.new(mock).empty!
    end
  end
end
