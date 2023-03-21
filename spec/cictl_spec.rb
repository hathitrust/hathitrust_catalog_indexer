require "spec_helper"

RSpec.describe CICTL::CICTL do
  describe "#initialize" do
    it "creates a CICTL::CICTL object" do
      cictl = described_class.new
      expect(cictl).to be_kind_of(CICTL::CICTL)
    end

    it "calls dotenv to initialize environment" do
      expect(Dotenv).to receive(:load)
      described_class.new
    end
  end
end
