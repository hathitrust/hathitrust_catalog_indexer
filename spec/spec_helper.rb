ENV["JRUBY_OPTS"] = "--debug #{ENV["JRUBY_OPTS"]}"

require "climate_control"
require "simplecov"
require "simplecov-lcov"
require "tmpdir"
require "webmock/rspec"

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = "coverage/lcov.info"
end
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter
])
SimpleCov.start do
  add_filter "/spec/"
end

WebMock.disable_net_connect!(allow: [
  "http://pushgateway:9091",
  "http://solr-sdr-catalog:9033",
  # for testing a non-working URL specifically
  "http://solr-sdr-catalog:1111"
])

require_relative "../lib/cictl"
require_relative "../lib/ht_traject"
require_relative "examples"

def fixture(filename)
  File.join(__dir__, "fixtures", filename)
end

def with_test_environment
  CICTL::SolrClient.new.empty!.commit!
  Dir.mktmpdir do |tmpdir|
    flags_directory = File.join(tmpdir, "flags")
    ClimateControl.modify(CICTL_ZEPHIR_FILE_TEMPLATE_PREFIX: "sample", FLAGS_DIRECTORY: flags_directory) do
      old_logfile_directory = HathiTrust::Services[:logfile_directory]
      old_journal_directory = HathiTrust::Services[:journal_directory]
      new_logfile_directory = File.join(tmpdir, "logs")
      new_journal_directory = File.join(tmpdir, "journal")
      FileUtils.mkdir(new_logfile_directory) unless File.exist?(new_logfile_directory)
      FileUtils.mkdir(new_journal_directory) unless File.exist?(new_journal_directory)
      HathiTrust::Services.register(:logfile_directory) { new_logfile_directory }
      HathiTrust::Services.register(:journal_directory) { new_journal_directory }
      yield tmpdir
      HathiTrust::Services.register(:logfile_directory) { old_logfile_directory }
      HathiTrust::Services.register(:journal_directory) { old_journal_directory }
    end
  end
end

def solr_count
  CICTL::SolrClient.new.count
end

def solr_deleted_count
  CICTL::SolrClient.new.count_deleted
end

def solr_ids(q = "*:*")
  solr_params = {q: q, wt: "ruby", rows: 100}
  response = CICTL::SolrClient.new.get("select", params: solr_params)
  response["response"]["docs"].map { |doc| doc["id"] }
end

def override_service(key, &block)
  around(:each) do |example|
    old_val = HathiTrust::Services[key]
    HathiTrust::Services.register(key, &block)
    example.run
    HathiTrust::Services.register(key) { old_val }
  end
end

RSpec.configure do |config|
  # boilerplate config from rspec --init
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # ours
  config.before(:each) do
    HathiTrust::Services.register(:print_holdings) do
      HathiTrust::MockPrintHoldings
    end
  end
end
