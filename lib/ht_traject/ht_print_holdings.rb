require_relative '../ht_secure_data'
require 'sequel'

module HathiTrust

  class PrintHoldings
    extend HathiTrust::SecureData
    DB = Sequel.connect("jdbc:mysql://#{db_machine}/#{db_db}?user=#{db_user}&password=#{db_password}")
    PHDB_Query = DB[:holdings_htitem_htmember].select(:volume_id, :member_id)
    
    # I use a db driver per thread to avoid any conflicts
    def self.get_print_holdings_hash(htids)
      htids = Array(htids)
      htid_map = Hash.new {|h,k| h[k] = []}
      PHDB_Query.where(:volume_id=>htids).each do |r|
        htid_map[r[:volume_id]] << r[:member_id]
      end
      
      htid_map
    end

  end
end


