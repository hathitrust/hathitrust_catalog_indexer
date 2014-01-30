require 'traject'
require 'match_map'
require 'ht_traject/ht_constants'
require 'ht_traject/ht_print_holdings'
require 'json'

module HathiTrust
  module Traject
    
    # An ItemSet is just, basically, a set of items that knows something 
    # about its constituents as a whole
    
    class ItemSet
      include Enumerable
      
      # Set up class-level translation maps so we don't have to mess with getting
      # them over and over again
      
      class << self
        attr_accessor :ht_ns, :ht_avail_us, :ht_avail_intl
      end
      self.ht_ns         = ::Traject::TranslationMap.new('ht/ht_namespace_map')
      self.ht_avail_us   = ::Traject::TranslationMap.new('ht/availability_map_ht')
      self.ht_avail_intl = ::Traject::TranslationMap.new('ht/availability_map_ht_intl')
        
      
      
      attr_reader :items
      def initialize
        @items = []
        @ph = {}
      end
      
      def add(item)
        @items << item
      end
      
      # Make it easy to get the size
      def size
        @items.size
      end
      
      
      # Basic iterator
      def each
        unless block_given?
          enum_for(:each)
        else
          @items.each do |i|
            yield i
          end
        end
      end
      
      # Some aggregate data
      def ht_ids
        unless @ids
          @ids = self.map {|i| i.htid.downcase }
        end
        @ids
      end
      
      
      def rights_list
        unless @rights_list
          @rights_list = self.map(&:rights).uniq
          if @rights_list.size == 1 && @rights_list[0] == 'nobody'
            @rights_list = ['tombstone']
          end
          @rights_list.uniq!
        end
        @rights_list
      end
      
      def last_update_dates
        unless @last_update_dates
          @last_update_dates = self.map(&:last_update_date).uniq
        end
        @last_update_dates
      end
      
      def collection_codes
        unless @collection_codes
          @collection_codes = self.map(&:collection_code).uniq
        end
        @collection_codes
      end
      
      def collections
        unless @collections
          @collections = self.map(&:collection).uniq
        end
      end
      
      def us_availability
        unless @us
          @us = self.map(&:us_availability).uniq
        end
        @us
      end
      
      def intl_availability
        unless @intl
          @intl = self.map(&:intl_availability).uniq
        end
        @intl
      end
      
      def fill_print_holdings!
        ids = self.ht_ids.flatten
        @ph = HathiTrust::PrintHoldings.get_print_holdings_hash(ids)
        self.each do |item|
          item.print_holdings = @ph[item.htid]
        end
      end
      
      def print_holdings
        return @ph.values.flatten.uniq
      end
      
      
      # Turn this item into the sort of json object
      # we want to store in solr
      
      def to_json
        rv = []
        needs_sorting = false
        self.each do |item|
          jsonrec = {
            'htid' => item.htid,
            'ingest' => item.last_update_date,
            'rights'  => item.rights,
            'heldby'   => item.print_holdings,
            'collection_code' => item.collection_code
          }
          if item.enum_chron
            jsonrec['enumcron'] = item.enum_chron
            needs_sorting = true
          end
          rv << jsonrec
        end

       
        if needs_sorting
          rv = sortHathiJSON(rv)
        end
        rv.to_json
      end
     

      def enumcronSort a,b
        matcha = /(\d{4})/.match a['enumcron']
        matchb = /(\d{4})/.match b['enumcron']
        if (matcha and matchb)
          return matcha[1] <=> matchb[1] unless (matcha[1] == matchb[1])
        end
        return a[:sortstring] <=> b[:sortstring]
      end
      
      # Create a sortable string based on the digit strings present in an
      # enumcron string

      def enumcronSortString str
        rv = '0'
        str.scan(/\d+/).each do |nums|
          rv += nums.size.to_s + nums
        end
        return rv
      end
      


     
      def sortHathiJSON arr
        # Only one? Never mind
        return arr if arr.size == 1

        # First, add the _sortstring entries
        arr.each do |h|
          if h.has_key? 'enumcron'
            h[:sortstring] = enumcronSortString(h['enumcron'])
          else
            h[:sortstring] = '0'
          end
        end

        # Then sort it
        arr.sort! {|a,b| self.enumcronSort(a, b)}
      
        # Then remove the sortstrings
        arr.each do |h|
          h.delete(:sortstring)
        end
        return arr
      end

      
      # The whole set (record) is considered Full Text iff there is at
      # least one item whose status is fulltext
      
      def us_fulltext?
        self.any? {|item| item.us_availability == HathiTrust::Constants::FT}
      end
      
      def intl_fulltext?
        self.any?  {|item| item.intl_availability == HathiTrust::Constants::FT}
      end


    end # end of Items
    
    
    # An individual item
    class Item
      
      DEFAULT_DATE = '00000000'
      
      attr_accessor :rights, :enum_chron, :last_update_date, :print_holdings, :collection_code
      attr_reader :htid, :set
      
      def initialize
        @print_holdings = []
      end
      
      def self.new_from_974(f)
        inst = self.new
        inst.rights = f['r']
        inst.htid   = f['u']
        inst.last_update_date = f['d'] || DEFAULT_DATE
        inst.enum_chron = f['z']
        inst.collection_code = f['c'] ? f['c'].downcase : inst.namespace
        inst
      end
      
      def htid=(s)
        return unless s
        @htid = s.downcase
        @namespace = namespace_for(@htid)
      end
      
      def source
        ItemSet.ht_ns[namespace]
      end

      def us_availability
        ItemSet.ht_avail_us[rights].first
      end

      def intl_availability
        ItemSet.ht_avail_intl[rights].first
      end
      
      
      def namespace
        unless @namespace
          @namespace = namespace_for(@htid)
        end
        @namespace
      end
      
      def namespace_for(htid)
        if ns_match = /^(.*?)\./.match(htid)
          ns_match[1]
        else
          :malformed_htid
        end
      end
      
      def malformed?
        self.namespace == :malformed_htid
      end
      
      def display_string
        [htid, last_update_date, enum_chron].join("|")
      end
      
    end # end of Item
    
    
    
    
  end # end of Modules
end
