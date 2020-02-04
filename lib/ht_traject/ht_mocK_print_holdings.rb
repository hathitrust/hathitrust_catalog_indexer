module HathiTrust

  class MockPrintHoldings

    def self.get_print_holdings_hash(htids)
      htids.each_with_object({}) {|id, h| h[id] = ['UM']}
    end
  end
end
