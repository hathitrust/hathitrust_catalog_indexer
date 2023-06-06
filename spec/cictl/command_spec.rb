# frozen_string_literal: true

require "spec_helper"

RSpec.describe CICTL::Command do
  describe "#initialize" do
    it "creates a CICTL::CICTL object" do
      cictl = described_class.new
      expect(cictl).to be_kind_of(CICTL::Command)
    end
  end
end
