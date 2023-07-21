# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/cictl/logfile_defaults"

RSpec.describe CICTL::LoggerFactory do
  def testlogger(verbose: false, log_file: test_log, quiet: false)
    CICTL::LoggerFactory.new(verbose: verbose, log_file: log_file, quiet: quiet).logger
  end

  after(:each) do
    remove_test_log
  end

  it "sends #error to $stderr" do
    skip "RSpec and captured stderr in the logger don't play well together"
    expect { testlogger.error "error shwoozle" }.to output(/shwoozle/).to_stderr_from_any_process
  end

  it "sends #fatal to $stderr" do
    skip "RSpec and captured stderr in the logger don't play well together"
    expect { testlogger.fatal "fatal shwoozle" }.to output(/shwoozle/).to_stderr_from_any_process
  end

  it "sends stuff to the logfile" do
    testlogger.error "error-in-file"
    expect(File.read(testlog_path)).to match(/error-in-file/)
  end

  it "does not send anything less than #error to STDERR" do
    skip "RSpec and captured stderr in the logger don't play well together"
    %i[debug info warn].each do |level|
      expect { testlogger.send(level, "#{level} shwoozle") }.not_to output(/shwoozle/).to_stderr_from_any_process
    end
  end

  it "doesn't send output to stderr in quiet mode" do
    skip "RSpec and captured stderr in the logger don't play well together"
    expect { testlogger(quiet: true).error("Error") }.not_to output(/Error/).to_stderr_from_any_process
  end
end
