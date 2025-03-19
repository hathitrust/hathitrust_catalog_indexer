# frozen_string_literal: true

require "spec_helper"

RSpec.describe CICTL::StopRelease do
  around(:each) do |example|
    with_test_environment do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  let(:stop_release) { described_class.new }

  describe ".new" do
    it "creates a CICTL::StopRelease object" do
      expect(stop_release).to be_kind_of(CICTL::StopRelease)
    end
  end

  describe "#path" do
    it "returns a path to the STOPCATALOGRELEASE file" do
      expect(stop_release.path).to include(CICTL::StopRelease::FILE_NAME)
    end

    it "returns default if FLAGS_DIRECTORY is not set" do
      ClimateControl.modify(FLAGS_DIRECTORY: nil) do
        expect(stop_release.path).to include(HathiTrust::Services[:data_directory])
      end
    end
  end

  describe "#write" do
    it "writes a file at `path`" do
      stop_release.write
      expect(File.exist?(stop_release.path)).to eq(true)
    end

    it "creates FLAGS_DIRECTORY if necessary" do
      new_flags_directory = File.join(@tmpdir, "a_strange_place_to_put_flags")
      ClimateControl.modify(FLAGS_DIRECTORY: new_flags_directory) do
        stop_release.write
        expect(stop_release.path).to include(new_flags_directory)
        expect(File.directory?(new_flags_directory)).to eq(true)
      end
    end
  end

  describe "#remove" do
    it "removes existing file at `path`" do
      stop_release.write
      stop_release.remove
      expect(File.exist?(stop_release.path)).to eq(false)
    end

    it "does nothing if there is no stop release file at `path`" do
      stop_release.remove
      expect(File.exist?(stop_release.path)).to eq(false)
    end
  end
end
