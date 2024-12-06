# frozen_string_literal: true

require "spec_helper"

RSpec.describe CICTL::CollectionMap do
  RSpec.shared_examples "translation map" do |map|
    it "is Traject::TranslationMap" do
      expect(map).to be_kind_of(Traject::TranslationMap)
    end

    it "contains a value we expect" do
      expect(map["miu"]).to eq("University of Michigan")
    end
  end

  describe "#to_translation_map" do
    context "with no_db flag unset (typical case)" do
      it_behaves_like "translation map", described_class.new.to_translation_map(no_db: false)
    end

    context "with no_db flag set (atypical case)" do
      it_behaves_like "translation map", described_class.new.to_translation_map(no_db: true)
    end
  end
end
