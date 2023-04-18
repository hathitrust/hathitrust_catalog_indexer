# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe CICTL::CollectionMap do
  describe "#collection_map" do
    it "contains a value we expect" do
      expect(described_class.new.collection_map).to have_key("miu")
    end
  end

  describe "#to_yaml" do
    it "returns parseable YAML" do
      expect { YAML.parse(described_class.new.to_yaml) }.not_to raise_error
    end
  end
end
