require "spec_helper"
require "services"
require "traject"

RSpec.describe "indexers/ht" do

  before(:each) do
    HathiTrust::Services.register(:push_metrics) { double(:push_metrics, increment_and_log_batch_line: nil) }
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

  RSpec::Matchers.define :match_solr_field do |field,expected|
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
  end

  it "can index a thing and have ht_items" do
    output = output_for(record("sample_record.json"))
    expect(output).to have_key("ht_json")

    ht_json = JSON.parse(output["ht_json"][0])


    solr_record = JSON.parse(File.read(fixture("sample_record_output.json")))

    # compare structure rather than string for ht_json
    expect(JSON.parse(solr_record["ht_json"]))
      .to eq(JSON.parse(output["ht_json"][0]))

  end

  it "has the expected fields in the output" do
    output = output_for(record("sample_record.json"))
    solr_record = JSON.parse(File.read(fixture("sample_record_output.json")))

    # don't compare this one
    solr_record.delete("ht_json")
    # compare the rest of the fields
    # output from traject/solr may not match in terms of arrayness; all fields
    # in solr output may not be in traject output
    solr_record.each do |k,v|
      expect(output[k]).to match_solr_field(k,v)
    end
  end
end

