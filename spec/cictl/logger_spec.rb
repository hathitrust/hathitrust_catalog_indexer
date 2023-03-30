require "spec_helper"

RSpec.describe CICTL::Logger do
  shared_examples "any logger" do |verbose, log_file|
    subject { described_class.logger(verbose: verbose, log_file: log_file) }
    it "sends #error to STDERR" do
      expect { subject.error "error shwoozle" }.to output(/shwoozle/).to_stderr
    end

    it "sends #fatal to STDERR" do
      expect { subject.fatal "fatal shwoozle" }.to output(/shwoozle/).to_stderr
    end
  end

  describe ".logger" do
    context "with a log file" do
      it_behaves_like "any logger", false, test_log
    end

    context "without a log file" do
      it_behaves_like "any logger", false, nil

      context "in verbose mode" do
        it "sends #debug to STDOUT" do
          logger = described_class.logger(verbose: true)
          expect { logger.debug "debug shwoozle" }.to output(/debug shwoozle/).to_stdout
        end
      end

      context "in non-verbose mode" do
        it "does not send #debug to STDOUT" do
          logger = described_class.logger
          expect { logger.debug "debug shwoozle" }.not_to output(/debug shwoozle/).to_stdout
        end
      end
    end
  end
end
