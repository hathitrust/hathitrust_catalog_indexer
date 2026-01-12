require "spec_helper"
require "services"
require "traject"
require "ht_traject/print_holdings_api"

RSpec.describe "indexers/ht" do
  before(:each) do
    # don't use the pushgateway in tests
    HathiTrust::Services.register(:push_metrics) do
      double(:push_metrics, increment_and_log_batch_line: nil)
    end
  end

  let(:traject_logger) do
    CICTL::LoggerFactory.new(quiet: true).logger(owner: "rspec")
  end

  let(:indexer) do
    Traject::Indexer::MarcIndexer.new(logger: traject_logger) do
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

  it "mock holdings puts holdings in the item records" do
    expect(HathiTrust::Services.print_holdings).to be HathiTrust::MockPrintHoldings
    htid1 = "hvd.32044083377234"
    htid2 = "coo1.ark:/13960/t6tx3x11f"
    holdings1 = ["umich"]
    holdings2 = ["umich"]

    output = output_for(record("sample_record.json"))
    ht_json = JSON.parse(output["ht_json"][0])
    expect(ht_json[0]["htid"]).to eq(htid1)
    expect(ht_json[0]["heldby"]).to eq(holdings1)
    expect(ht_json[1]["htid"]).to eq(htid2)
    expect(ht_json[1]["heldby"]).to eq(holdings2)
  end

  context "with webmocked holdings api" do
    let(:holdings_api_test_url) { "https://holdings-api.invalid" }
    let(:holdings_api_endpoint) { "#{holdings_api_test_url}/v1/record_held_by" }

    around(:each) do |example|
      ClimateControl.modify HOLDINGS_API_URL: holdings_api_test_url do
        example.run
      end
    end

    it "can use the print holdings API" do
      old_ph = HathiTrust::Services.print_holdings
      HathiTrust::Services.register(:print_holdings) { HathiTrust::PrintHoldingsAPI }

      htid1 = "hvd.32044083377234"
      htid2 = "coo1.ark:/13960/t6tx3x11f"
      holdings1 = ["inst1", "inst2", "inst3"]
      holdings2 = ["inst1", "inst2"]

      solr_record = JSON.parse(File.read(fixture("sample_record_output.json")))
      JSON.parse(solr_record["ht_json"])

      request_body_matcher = ->(body) do
        params = JSON.parse(body)
        ht_items_params = JSON.parse(params["ht_json"])

        %w[id format oclc].each do |field|
          expect(params["field"]).to eq solr_record["field"]
        end
        # not using the concordance in testing
        expect(params["oclc_search"]).to eq solr_record["oclc"]

        expect(ht_items_params[0]["htid"]).to eq(htid1)
        expect(ht_items_params[1]["htid"]).to eq(htid2)
      end

      require "pry"

      stub_request(:post, holdings_api_endpoint)
        .with(body: request_body_matcher, headers: {"Content-Type" => "application/json"})
        .to_return(status: 200, body:
                   [
                     {
                       item_id: htid1,
                       organizations: holdings1
                     },
                     {
                       item_id: htid2,
                       organizations: holdings2
                     }
                   ].to_json, headers: {"Content-Type" => "application/json"})

      output = output_for(record("sample_record.json"))
      JSON.parse(output["ht_json"][0])
      ht_json = JSON.parse(output["ht_json"][0])
      expect(ht_json[0]["htid"]).to eq(htid1)
      expect(ht_json[0]["heldby"]).to eq(holdings1)
      expect(ht_json[1]["htid"]).to eq(htid2)
      expect(ht_json[1]["heldby"]).to eq(holdings2)
    ensure
      HathiTrust::Services.register(:print_holdings) { old_ph }
    end
  end
end
