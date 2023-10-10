require_relative "../services"

module HathiTrust
  class PrintHoldings
    def self.query
      return @query if @query

      nocache_volume_id = Sequel.lit('SQL_NO_CACHE volume_id')
      @query = Services[:db][:holdings_htitem_htmember].join(:ht_institutions, inst_id: :member_id).select(nocache_volume_id, :mapto_inst_id).distinct
    end

    # I use a db driver per thread to avoid any conflicts
    def self.get_print_holdings_hash(htids)
      htids = Array(htids)
      htid_map = Hash.new { |h, k| h[k] = [] }

      # Need to do this in blocks because I'm getting failures (timeouts) from mysql
      htids.each_slice(20) do |ids|
        query.where(volume_id: ids).each do |r|
          htid_map[r[:volume_id]] << r[:mapto_inst_id]
        end
      end

      htid_map
    end
  end
end
