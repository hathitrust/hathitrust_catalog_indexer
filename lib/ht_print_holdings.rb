require_relative 'ht_dbh.rb'
module HathiTrust
  class PrintHoldings
    
    # I use a db driver per thread to avoid any conflicts
    def self.get_print_holdings_hash(htids)
      htids = Array(htids)
      Thread.current[:phdbdbh] ||= HathiTrust::DBH.new
                  
      query = "select volume_id, member_id from holdings_htitem_htmember where volume_id IN (#{self.commaify(htids)})"
      
      
      htid_map = {}
      Thread.current[:phdbdbh].query(query).each do |pair|
        htid, inst = *pair
        htid_map[htid] ||= []
        htid_map[htid] << inst
      end
      
      htid_map
    end
    
  
    
    # A simple "commaify" to (naively) quote values and make a list for SQL "IN"
    # NOT SAFE for general data, but just fine for HathiTrust IDs, which have no 
    # double-quotes in them.
    
    def self.commaify(a)
      a = Array(a)
      return a.map{|v| "\"#{v}\""}.join(', ')
    end
    
  end
end


