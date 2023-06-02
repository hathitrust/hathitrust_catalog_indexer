# frozen_string_literal: true

require "spec_helper"

RSpec.describe CICTL::LoggerFactory, skip: true do
  shared_examples "any logger" do |verbose, log_file|
    subject { described_class.new(verbose: verbose, log_file: log_file).logger }
    it "sends #error to STDERR" do
      expect { subject.error "error shwoozle" }.to output(/shwoozle/).to_stderr
    end

    it "sends #fatal to STDERR" do
      expect { subject.fatal "fatal shwoozle" }.to output(/shwoozle/).to_stderr
    end

    it "does not send anything less than #error to STDERR" do
      %i[debug info warn].each do |level|
        expect { subject.send(level, "#{level} shwoozle") }.not_to output(/shwoozle/).to_stderr
      end
    end
  end

  describe "#logger" do
    context "with a log file" do
      it_behaves_like "any logger", false, test_log
    end

    context "without a log file" do
      it_behaves_like "any logger", false, nil
    end
  end
end
