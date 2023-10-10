require 'traject'
require 'match_map'
require 'ht_traject/ht_constants'
require 'ht_traject/ht_macros'
require "services"

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
        @ph    = {}
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
        return enum_for(:each) unless block_given?

        @items.each do |i|
          yield i
        end
      end

      # Some aggregate data
      def ht_ids
        @ids ||= map { |i| i.htid.downcase }
        @ids
      end

      def rights_list
        unless @rights_list
          @rights_list = flat_map(&:rights).uniq
          @rights_list = ['tombstone'] if @rights_list.size == 1 && @rights_list[0] == 'nobody'
          @rights_list.uniq!
        end
        @rights_list
      end

      def last_update_dates
        @last_update_dates ||= map(&:last_update_date).uniq
        @last_update_dates
      end

      def collection_codes
        @collection_codes ||= map(&:collection_code).uniq
        @collection_codes
      end

      def collections
        @collections ||= map(&:collection).uniq
      end

      def us_availability
        @us ||= map(&:us_availability).uniq
        @us
      end

      def intl_availability
        @intl ||= map(&:intl_availability).uniq
        @intl
      end

      def fill_print_holdings!
        ids = ht_ids.flatten
        @ph = HathiTrust::Services[:print_holdings].get_print_holdings_hash(ids)
        each do |item|
          item.print_holdings = @ph[item.htid]
        end
      end

      def print_holdings
        @ph.values.flatten.uniq
      end

      # Turn this item into the sort of json object
      # we want to store in solr

      def to_json(platform)
        rv            = []
        needs_sorting = false
        each do |item|
          jsonrec = {
            'htid' => item.htid,
            'newly_open' => item.newly_open,
            'ingest' => item.last_update_date,
            'rights' => item.rights,
            'heldby' => item.print_holdings,
            'collection_code' => item.collection_code
          }

          if item.enum_chron
            jsonrec['enumcron'] = item.enum_chron
            needs_sorting       = true
          end

          if item.enum_pubdate
            jsonrec['enum_pubdate']       = item.enum_pubdate
            jsonrec['enum_pubdate_range'] = HathiTrust::Traject::Macros::HTMacros.compute_date_range(item.enum_pubdate.to_i)
          end

          if platform == :ht
            jsonrec['dig_source'] = item.dig_source if item.dig_source
          end

          rv << jsonrec
        end

        rv = sortHathiJSON(rv) if needs_sorting
        rv.to_json
      end

      def enumcronSort(a, b)
        matcha = /(\d{4})/.match a['enumcron']
        matchb = /(\d{4})/.match b['enumcron']
        if matcha && matchb && (matcha[1] != matchb[1])
          #          return matcha[1].to_i <=> matchb[1].to_i
        end
        a[:sortstring] <=> b[:sortstring]
      end

      # Create a sortable string based on the digit strings present in an
      # enumcron string

      def enumcronSortString(str)
        rv = '0'
        str.scan(/\d+/).each do |nums|
          rv += nums.size.to_s + nums
        end
        rv
      end

      def sortHathiJSON(arr)
        # Only one? Never mind
        return arr if arr.size <= 1

        # First, add the sortstring entries
        arr.each do |h|
          h[:sortstring] = if h.has_key? 'enumcron'
                             enumcronSortString(h['enumcron'])
                           else
                             '0'
                           end
        end

        # Then sort it
        arr.sort! { |a, b| enumcronSort(a, b) }

        # Then remove the sortstrings
        arr.each do |h|
          h.delete(:sortstring)
        end
        arr
      end

      # The whole set (record) is considered Full Text iff there is at
      # least one item whose status is fulltext

      def us_fulltext?
        any? { |item| item.us_availability == HathiTrust::Constants::FT }
      end

      def intl_fulltext?
        any? { |item| item.intl_availability == HathiTrust::Constants::FT }
      end
    end

    # end of Items

    # An individual item
    class Item
      DEFAULT_DATE = '00000000'.freeze

      attr_accessor :rights, :enum_chron, :last_update_date, :print_holdings,
                    :collection_code, :dig_source
      attr_reader :htid, :set, :enum_pubdate, :enum_pubdate_range

      attr_accessor :title_sortkey, :author_sortkey

      def initialize
        @print_holdings = []
        @rights         = []
      end

      def self.new_from_974(f)
        inst = new
        inst.rights << f['r']
        inst.htid             = f['u']
        inst.last_update_date = f['d'] || DEFAULT_DATE
        inst.enum_chron       = f['z']
        inst.enum_pubdate     = f['y']
        inst.collection_code  = f['c'] ? f['c'].downcase : inst.namespace
        inst.dig_source       = f['s'] ? f['s'].downcase : nil

        inst.rights << inst.newly_open

        inst
      end

      def htid=(s)
        return unless s

        @htid      = s.downcase
        @namespace = namespace_for(@htid)
      end

      def enumchron_sortstring
        return '0000' if enum_chron.nil?

        digit_strings = enum_chron.scan(/\d+/).map do |digits|
          digits.size.to_s + digits
        end

        if digit_strings.empty?
          '0000'
        else
          digit_strings
        end
      end

      def enum_pubdate=(e)
        if e && (e =~ /\d/)
          @enum_pubdate       = ('%04d' % e.to_i)
          @enum_pubdate_range = HathiTrust::Traject::Macros::HTMacros.compute_date_range(@enum_pubdate)
        else
          @enum_pubdate       = nil
          @enum_pubdate_range = nil
        end
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

      def newly_open
        'newly_open' if HathiTrust::Constants::NewlyOpen.include? htid
      end

      def namespace
        @namespace ||= namespace_for(@htid)
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
        namespace == :malformed_htid
      end

      def display_string
        [htid, last_update_date, enum_chron, enum_pubdate, enum_pubdate_range, title_sortkey, author_sortkey].join('|')
      end
    end # end of Item
  end # end of Modules
end
