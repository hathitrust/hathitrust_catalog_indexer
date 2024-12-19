# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/cictl/logfile_defaults"
require_relative "../../lib/services"

RSpec.describe CICTL::LoggerFactory do
  around(:each) do |example|
    ClimateControl.modify(CICTL_SEMANTIC_LOGGER_SYNC: "1") do
      with_test_environment do |tmpdir|
        example.run
      end
    end
  end

  def testlogger(verbose: false, log_file: test_log, quiet: false)
    CICTL::LoggerFactory.new(verbose: verbose, log_file: log_file, quiet: quiet).logger
  end

  context "with log_file '-'" do
    let(:test_log) { "-" }

    it "sends #error to $stderr" do
      expect {
        testlogger.error "error error-via-error"
      }.to output(/error-via-error/).to_stdout_from_any_process
    end

    it "sends #fatal to $stderr" do
      expect {
        testlogger.fatal "fatal shwoozle"
      }.to output(/shwoozle/).to_stdout_from_any_process
    end
    it "sends #info to $stdout" do
      expect {
        testlogger.info "some info"
      }.to output(/some info/).to_stdout_from_any_process
    end

    it "doesn't send output to stdout in quiet mode" do
      expect {
        testlogger(quiet: true).error("Error")
      }.not_to output(/Error/).to_stdout_from_any_process
    end
  end

  context "with test log_file" do
    let(:test_log) { "TEST_LOG.txt" }
    let(:test_log_path) { File.join(HathiTrust::Services[:logfile_directory], test_log) }

    it "sends #error to $stderr" do
      expect {
        testlogger.error "error error-via-error"
      }.to output(/error-via-error/).to_stderr_from_any_process
    end

    it "sends #fatal to $stderr" do
      expect {
        testlogger.fatal "fatal shwoozle"
      }.to output(/shwoozle/).to_stderr_from_any_process
    end

    it "sends #error to the logfile" do
      testlogger.error "error-in-file"
      expect(File.read(test_log_path)).to match(/error-in-file/)
    end

    it "sends #info to the logfile" do
      testlogger.info "some info"
      expect(File.read(test_log_path)).to match(/some info/)
    end

    it "does not send anything less than #error to STDERR" do
      %i[debug info warn].each do |level|
        expect {
          testlogger.send(level, "#{level} shwoozle")
        }.not_to output(/shwoozle/).to_stderr_from_any_process
      end
    end

    it "doesn't send output to stderr in quiet mode" do
      expect {
        testlogger(quiet: true).error("Error")
      }.not_to output(/Error/).to_stderr_from_any_process
    end
  end

  it "maps --log=daily into today's date" do
    testlogger(log_file: "daily").info "info-in-file"
    expect(Dir.children(HathiTrust::Services[:logfile_directory]).first).to match(/daily_\d{8}\.log/)
  end

  it "maps --log=full into today's date" do
    testlogger(log_file: "full").info "info-in-file"
    expect(Dir.children(HathiTrust::Services[:logfile_directory]).first).to match(/full_\d{8}\.log/)
  end
end
