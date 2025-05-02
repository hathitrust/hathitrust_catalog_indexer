# frozen_string_literal: true

require "spec_helper"
require "webmock"
require "ht_traject/print_holdings_api"
require "ht_traject/ht_item"

RSpec.describe HathiTrust::PrintHoldingsAPI do
  let(:id) { "000000001" }
  let(:format) { ["Book"] }
  let(:oclc) { ["2779601"] }
  let(:oclc_search) { ["2779601"] }

  let(:item_set) do
    item = HathiTrust::Traject::Item.new.tap do |i|
      i.htid = "mdp.39015066356547"
      i.last_update_date = "20250111"
      i.rights = ["ic", nil]
      i.collection_code = "miu"
      i.enum_chron = "v.1"
      i.dig_source = "google"
    end

    HathiTrust::Traject::ItemSet.new.tap do |item_set|
      item_set.add(item)
    end
  end

  let(:params) do
    {
      ht_items: item_set,
      id: id,
      format: format,
      oclc: oclc,
      oclc_search: oclc_search
    }
  end

  context "with webmocked holdings api" do
    let(:holdings_api_test_url) { "https://holdings-api.invalid" }
    let(:holdings_api_endpoint) { "#{holdings_api_test_url}/v1/record_held_by" }

    around(:each) do |example|
      ClimateControl.modify HOLDINGS_API_URL: holdings_api_test_url do
        example.run
      end
    end

    # set up mocked endpoint
    it "returns output from holdings API endpoint" do
      stub_request(:post, holdings_api_endpoint)
        .to_return(status: 200, body:
                   [
                     {
                       item_id: "mdp.39015066356547",
                       organizations: ["umich", "someinst"]
                     }
                   ].to_json, headers: {"Content-Type" => "application/json"})

      print_holdings = described_class.get_print_holdings_hash(**params)

      expect(print_holdings).to eq({"mdp.39015066356547" => ["umich", "someinst"]})
    end

    it "returns output from holdings API endpoint" do
      expected_ht_json = [
        {
          htid: "mdp.39015066356547",
          newly_open: nil,
          ingest: "20250111",
          rights: ["ic", nil],
          heldby: [],
          collection_code: "miu",
          enumcron: "v.1",
          dig_source: "google"
        }
      ].to_json

      stub_request(:post, holdings_api_endpoint)
        .with(
          body: {
            id: "000000001",
            format: ["Book"],
            oclc: ["2779601"],
            oclc_search: ["2779601"],
            ht_json: expected_ht_json
          },

          headers: {
            "Content-Type" => "application/json"
          }
        )
        .to_return(status: 200, body: [].to_json,
          headers: {"Content-Type" => "application/json"})

      expect { described_class.get_print_holdings_hash(**params) }.not_to raise_exception
    end
  end
end
