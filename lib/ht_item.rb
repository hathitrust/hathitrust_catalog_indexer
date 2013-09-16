require 'traject'
require 'match_map'
require 'ht_constants'
require 'ht_print_holdings'

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
      self.ht_ns         = ::Traject::TranslationMap.new('ht_namespace_map')
      self.ht_avail_us   = ::Traject::TranslationMap.new('availability_map_ht')
      self.ht_avail_intl = ::Traject::TranslationMap.new('availability_map_ht_intl')
        
      
      
      attr_reader :items
      def initialize
        @items = []
      end
      
      def add(item)
        @items << item
      end
      
      def size
        @items.size
      end
      
      def each
        unless block_given?
          enum_for(:each)
        else
          @items.each do |i|
            yield i
          end
        end
      end
      
      
      def rights_list
        unless @rights_list
          @rights_list = self.map(&:rights)
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
      
      def sources
        unless @sources
          @sources = self.map(&:source).uniq
        end
        @sources
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
        ids = self.map(&:ht_ids).flatten
        @ph = HathiTrust::PrintHoldings.get_print_holdings_hash(ids)
        self.each do |item|
          item.print_holdings = @ph[item.htid]
        end
      end
      
      def print_holdings
        return @ph.values.flatten.uniq
      end
        
      
      
      # The whole set (record) is considered Full Text iff there is at
      # least one item whose status is fulltext
      
      def us_fulltext?
        self.any? {|item| item.us_availability == HathiTrust::Constants::FT}
      end
      
      def intl_fulltext?
        self.any?  {|item| item.intl_availability == HathiTrust::Constants::FT}
      end
      
      
      def ht_ids
        unless @ids
          @ids = self.map {|i| i.htid.downcase }
        end
        @ids
      end
      
    end
    
    
    # An individual item
    class Item
      
      DEFAULT_DATE = '00000000'
      
      attr_accessor :rights, :enum_chron, :last_update_date, :print_holdings
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
        inst
      end
      
      def htid=(s)
        @htid = s.downcase
        @namespace = namespace_for(@htid)
      end
      
      def source
        ::Traject::TranslationMap.new('ht_namespace_map')[namespace]
      end

      def us_availability
        ::Traject::TranslationMap.new('availability_map_ht')[rights].first
      end

      def intl_availability
        ::Traject::TranslationMap.new('availability_map_ht_intl')[rights].first
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
      
      
    end
    
    
    
    
  end
end
