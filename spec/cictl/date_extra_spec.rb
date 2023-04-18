# frozen_string_literal: true

require "spec_helper"

RSpec.describe Date do
  describe ".with" do
    it "returns Date unchanged" do
      today = described_class.today
      expect(described_class.with(today)).to equal today
    end

    it "returns Date based on String" do
      expect(described_class.with("2000-01-01")).to eq Date.parse("2000-01-01")
    end

    it "raises on bogus date" do
      expect { described_class.with("this is not even remotely datelike") }
        .to raise_error(CICTL::CICTLError)
    end
  end
end
