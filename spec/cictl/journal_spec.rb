# frozen_string_literal: true

require "spec_helper"

RSpec.describe CICTL::Journal do
  around(:each) do |example|
    with_test_environment do |tmpdir|
      example.run
    end
  end

  describe "#initialize" do
    it "creates a CICTL::Journal object" do
      journal = described_class.new
      expect(journal).to be_kind_of(CICTL::Journal)
    end
  end

  describe "#file" do
    it "returns a filename matching the class regular expression" do
      journal = described_class.new
      expect(journal.file).to match(CICTL::Journal::FILENAME_PATTERN)
    end
  end

  describe "#write" do
    context "with default date" do
      it "creates the file" do
        journal = described_class.new
        journal.write!
        expect(File.exist?(journal.path)).to eq true
        expect(journal.path).to match((Date.today - 1).strftime("%Y%m%d"))
      end
    end

    context "with another date" do
      it "creates the file" do
        date = Date.new(2020, 6, 1)
        journal = described_class.new(date: date)
        journal.write!
        expect(File.exist?(journal.path)).to eq true
        expect(journal.path).to match(date.strftime("%Y%m%d"))
      end
    end
  end
end
