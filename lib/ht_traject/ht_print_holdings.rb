
      require_relative 'ht_dbh'


module HathiTrust

  class MockPrintHoldings

    def self.get_print_holdings_hash(htids)
      htids.each_with_object({}) {|id, h| h[id] = ['UM']}
    end
  end

  class PrintHoldings

    def self.query
      return @query if @query
      @query = HathiTrust::DBH::DB[:holdings_htitem_htmember].select(:volume_id, :member_id)
    end
    
    # I use a db driver per thread to avoid any conflicts
    def self.get_print_holdings_hash(htids)
      htids = Array(htids)
      htid_map = Hash.new {|h,k| h[k] = []}
      self.query.where(:volume_id=>htids).each do |r|
        htid_map[r[:volume_id]] << r[:member_id]
      end
      
      htid_map
    end

  end
end


