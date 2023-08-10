# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/services"

RSpec.describe CICTL::LoggerFactory do
  def testlogger(verbose: false, log_file: test_log, quiet: false)
    CICTL::LoggerFactory.new(verbose: verbose, log_file: log_file, quiet: quiet).logger
  end

  after(:each) do
    remove_test_log
  end

  it "sends #error to $stderr" do
    expect {
      testlogger.error "error error-via-error"
      testlogger.close
    }.to output(/error-via-error/).to_stderr_from_any_process
  end
end
