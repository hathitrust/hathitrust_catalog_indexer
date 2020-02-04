
require_relative 'ht_dbh'    



module HathiTrust

  class PrintHoldings

    def self.query
      return @query if @query
      @query = HathiTrust::DBH::DB[:holdings_htitem_htmember].select(:volume_id, :member_id)
    end
    
    # I use a db driver per thread to avoid any conflicts
    def self.get_print_holdings_hash(htids)
      htids = Array(htids)
      htid_map = Hash.new {|h,k| h[k] = []}

      # Need to do this in blocks because I'm getting failures (timeouts) from mysql
      htids.each_slice(20) do |ids|
        self.query.where(:volume_id=>ids).each do |r|
          htid_map[r[:volume_id]] << r[:member_id]
        end
      end
      
      
      htid_map
    end

  end
end


