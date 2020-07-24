require_relative 'ht_dbh'

module HathiTrust
  class OCLCResolution
    def self.query
      return @query if @query
      sql_expr = "select SQL_NO_CACHE o2.oclc, o2.canonical from oclc_concordance o1, oclc_concordance o2
                  where o2.canonical = o1.canonical and (o1.oclc = ? OR o1.canonical = ?)"


      raw_query = HathiTrust::DBH::DB[sql_expr, :$oclc, :$oclc]
      @query = raw_query.prepare(:select, :oclc_concordance)
    end

    def self.all_resolved_oclcs(oclcs)
      oclcs = Array(oclcs)
      oclcs.flat_map{|o| self.query.call(oclc: o)}.flat_map{|x| [x[:oclc], x[:canonical]]}.uniq
    end

  end
end
