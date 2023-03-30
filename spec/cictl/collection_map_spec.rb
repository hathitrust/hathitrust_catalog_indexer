require "spec_helper"
require "yaml"

RSpec.describe CICTL::CollectionMap do
  describe ".new" do
    it "creates a CICTL::CollectionMap" do
      expect(described_class.new).to be_a_kind_of(CICTL::CollectionMap)
    end
  end

  describe "#to_yaml" do
    it "returns a YAML string" do
      expect(described_class.new.to_yaml).to be_a_kind_of(String)
    end

    it "returns parseable YAML" do
      expect { YAML.parse(described_class.new.to_yaml) }.not_to raise_error
    end
  end
end
