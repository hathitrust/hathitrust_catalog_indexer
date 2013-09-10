require 'traject'
require 'match_map'

module HathiTrust
  module Traject
    
    # An ItemSet is just, basically, a set of items that knows something 
    # about its constituents as a whole
    
    class ItemSet
      
      # Set up class-level translation maps so we don't have to mess with getting
      # them over and over again
      
      class << self
        attr_accessor :ht_ns, :ht_avail_us, :ht_avail_intl
      end
      self.ht_ns         = Traject::TranslationMap.new('ht_namespace_map')
      self.ht_avail_us   = Traject::TranslationMap.new('availability_map_ht')
      self.ht_avail_intl = Traject::TranslationMap.new('availability_map_ht_intl')
        
      
      
      attr_reader :items
      def initialize
        @items = []
      end
      
      def add(item)
        item.set = self
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
            
    end
    
    class Item
      
      DEFAULT_DATE = '00000000'
      
      attr_accessor :rights, :enum_chron, :last_update_date
      attr_reader :htid, :set
      
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
      
      def us_availability
        Traject::TranslationMap.new('availability_map_ht')[rights]
      end

      def intl_availability
        Traject::TranslationMap.new('availability_map_ht_intl')[rights]
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
      
    end
    
    
  end
end
