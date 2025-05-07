module HathiTrust
  class MockPrintHoldings
    # Indicate that umich holds all items
    def self.get_print_holdings_hash(ht_json:, **_params)
      JSON.parse(ht_json).map do |item|
        [item["htid"], ["umich"]]
      end.to_h
    end
  end
end
