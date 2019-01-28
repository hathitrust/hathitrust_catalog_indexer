require_relative 'ht_dbh'
require 'set'
module HathiTrust
  module Constants

    SO = "Search only"
    FT = "Full text"
    # OPEN_1923_ROWS = DBH::DB[:mb_coll_item].where(mcoll_id: 149827760)
    # OPEN_1923 = Set.new(OPEN_1923_ROWS.select_map(:extern_item_id))
    #
    # A place to put things that will become newly open on Jan 1
    NewlyOpen = []
  end
end
