require "spec_helper"
require "services"
require "traject"

RSpec.describe "indexers/ht" do
  before(:each) do
    # don't use the pushgateway in tests
    HathiTrust::Services.register(:push_metrics) do
      double(:push_metrics, increment_and_log_batch_line: nil)
    end
  end

  let(:indexer) do
    Traject::Indexer::MarcIndexer.new do
      [
        "./writers/null.rb",
        "./indexers/common.rb",
        "./indexers/common_ht.rb",
        "./indexers/ht.rb"
      ].each { |path| load_config_file(path) }
    end
  end

  RSpec::Matchers.define :match_solr_field do |field, expected|
    match do |actual|
      actual == expected || actual == [expected]
    end

    failure_message do |actual|
      "expected field #{field} to be #{expected.inspect}, was #{actual.inspect}"
    end
  end

  def record(fixture)
    MARC::Record.new_from_hash(JSON.parse(File.read(fixture("sample_record.json"))))
  end

  def output_for(record)
    indexer.process_record(record).output_hash
  end

  it "creates an ht_json field with the expected structure" do
    output = output_for(record("sample_record.json"))
    expect(output).to have_key("ht_json")

    output_ht_json = JSON.parse(output["ht_json"][0])
    solr_record = JSON.parse(File.read(fixture("sample_record_output.json")))
    solr_record_ht_json = JSON.parse(solr_record["ht_json"])

    expect(solr_record_ht_json)
      .to eq(output_ht_json)
  end

  it "has the expected fields in the output" do
    output = output_for(record("sample_record.json"))
    solr_record = JSON.parse(File.read(fixture("sample_record_output.json")))

    # don't compare this one
    solr_record.delete("ht_json")
    # compare the rest of the fields
    # output from traject/solr may not match in terms of arrayness; all fields
    # in solr output may not be in traject output
    solr_record.each do |k, v|
      expect(output[k]).to match_solr_field(k, v)
    end
  end

  it "puts holdings in the item records" do
    # mock the call to Services.print_holdings
    htid1 = "hvd.32044083377234"
    htid2 = "coo1.ark:/13960/t6tx3x11f"
    holdings1 = ["inst1", "inst2", "inst3"]
    holdings2 = ["inst1", "inst2"]

    old_ph = HathiTrust::Services.print_holdings
    ph_double = double(:print_holdings)
    expect(ph_double).to receive(:get_print_holdings_hash)
      .with([htid1, htid2])
      .and_return({htid1 => holdings1, htid2 => holdings2})

    HathiTrust::Services.register(:print_holdings) { ph_double }

    output = output_for(record("sample_record.json"))
    ht_json = JSON.parse(output["ht_json"][0])
    expect(ht_json[0]["htid"]).to eq(htid1)
    expect(ht_json[0]["heldby"]).to eq(holdings1)
    expect(ht_json[1]["htid"]).to eq(htid2)
    expect(ht_json[1]["heldby"]).to eq(holdings2)
  ensure
    HathiTrust::Services.register(:print_holdings) { old_ph }
  end
end
