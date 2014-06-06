require_relative '../ht_secure_data'
require 'sequel'

module HathiTrust

  class PHDB_Query
    def initialize(sd = HathiTrust::SecureData.new)
      connection =
      q = connection[:holdings_htitem_htmember].select(:volume_id, :member_id)
    end
  end

  class PrintHoldings

    DB = Sequel.connect("jdbc:mysql://#{sd.db_machine}/#{sd.db_db}?user=#{sd.db_user}&password=#{sd.db_password}")
    PHDB_Query = DB[:holdings_htitem_htmember].select(:volume_id, :member_id)
    
    # I use a db driver per thread to avoid any conflicts
    def self.get_print_holdings_hash(htids)
      htids = Array(htids)
      htid_map = Hash.new {|h,k| h[k] = []}
      PHDB_QUERY.where(:volume_id=>htids).each do |r|
        htid_map[r.volume_id] << r[:member_id]
      end
      
      htid_map
    end
        
  end
end


