require 'rubygems'
require 'json'
require 'marcspec'
require 'jlogger'
require 'java'
require 'pp'
require 'jdbc-helper'
#require 'mysql-connector-java-5.1.17-bin.jar'
#require 'secure_data.rb'

module MARC2Solr
  module Custom
    module UMich

      include JLogger::Simple


      # Create a marc spec for SerialTitleRest

      SerialTitleRestFieldsSpec = MARCSpec::SolrFieldSpec.fromHash(
        {
        :solrField => 'serialTitleRest_internal',
        :specs => [
          ['130', 'adfgklmnoprst'],
          ["210", "ab"],
          ["222", "ab"],
          ["240", "adfgklmnprs"],
          ["246", "abdenp"],
          ["247", "abdenp"],
          ["730", "anp"],
          ["740", "anp"],
          ["765", "st"],
          ["767", "st"],
          ["770", "st"],
          ["772", "st"],
          ["775", "st"],
          ["776", "st"],
          ["777", "st"],
          ["780", "st"],
          ["785", "st"],
          ["786", "st"],
          ["787", "st"]
        ]
      })


      # Get the country map and the HT Source map
      COPMAP = MARCSpec::Map.fromFile(File.dirname(__FILE__) + '/../translation_maps/country_map.rb')

      HTSOURCEMAP = MARCSpec::Map.fromFile(File.dirname(__FILE__) + '/../translation_maps/ht_namespace_map.rb')


      def self.country_of_pub(doc, r)
        data = []
        return data unless r['008'];
        [r['008'].value[15..17], r['008'].value[17..17]].each do |s|
          data <<  COPMAP[s.gsub(/[^a-z]/, '')] if s
        end
        return data.compact
      end


      # Get the language(s)
      def self.getLanguage(doc, r)
        rawdata  = []

        # 008
        if r['008'] and r['008'].value[35..37]
          rawdata <<  r['008'].value[35..37].downcase
        end

        # 041, subfields adej
        codes = ['a', 'd', 'e', 'j']
        r.find_by_tag('041').each do |f|
          f.sub_values(codes).each do |v|
            unless v.size.modulo(3) == 0
    #          puts "getLanguage: #{r['001'].value} Invalid data length #{v.size} in 041. #{f.to_s}"
              next
            end
            v.split(//).each_slice(3) do |c|
              rawdata << langcode = c.join('').downcase
            end
          end
        end
        return rawdata
      end


      # For each title (245), extract the given codes, and then
      # return both that whole string and the the string with the
      # number of charactes indicated by ind2 (the "non-filing chars) removed.
      #
      # Could get more efficiency by passing data from title fields to each other down
      # the line (maybe shave 2-3% off total processing time)

      def self.getTitle(doc, r, codes, strip=true, index=nil)
        data = []
        fields = r.find_by_tag('245')
        # Do we want a particular one?
        if (index)
          fields = [fields[index - 1]].compact
          return [] if fields.size == 0
        end
        fields.each do |f|
          subvals = f.sub_values(codes)
          subvals.compact!
          if subvals.size > 0
            val = subvals.join(' ')
            data << val
            if strip
              ind2 = f.indicator2.to_i
              if ind2 > 0 and ind2 < val.length
                data << val[ind2..-1]
              end
            end
          end
        end
        return data
      end

      def self.getSerialTitle doc, r, codes
        if doc['format'] and doc['format'].include? 'Serial'
          return self.getTitle(doc, r, codes)
        else
          return []
        end
      end


      def self.getSerialTitleRest doc, r
        if doc['format'] and doc['format'].include? 'Serial'
          return SerialTitleRestFieldsSpec.marc_values(r)
        else
          return []
        end
      end


      def self.getTitleSortable doc, r, codes
        f = r['245'] # only the first one!
        unless f and f.sub_values().join('') =~ /\S/
          log.error "No valid 245 title for record {}", r['001'].value
          return nil
        end
        subvals = f.sub_values(codes)
        subvals.compact!
        if subvals.size > 0
          val = subvals.join(' ')
          ind2 = f.indicator2.to_i
          if ind2 > 0 and ind2 < val.length
            val = val[ind2..-1]
          end
        else
          log.error "No valid 245 title for record {}", r['001'].value
          return nil
        end
        return val.gsub(/[^\p{L}\p{N}]/u, ' ').gsub(/\s+/, ' ').strip.downcase
      end

      def self.getDateRange(date, r)
        if date < "1500"
          return "Pre-1500"
        end

        case date.to_i
        when 1500..1800 then
          century = date[0..1]
          return century + '00-' + century + '99'
        when 1801..2100 then
          decade = date[0..2]
          return decade + "0-" + decade + "9";
        else
          log.debug "getDateRange: {} invalid date {}", r['001'].value, date
        end
      end

      def self.publishDateRange(doc,r)
        pubdate = doc['publishDate']
        return [] unless pubdate and pubdate.size > 0
        return self.getDateRange pubdate[0], r
      end

      def self.most_recent_cat_date doc, r
         return r.find_by_tag('972').map{|sf| sf['c']}.max || nil
      end


      ##############################################
      # Deal with enumchron for Hathi
      ##############################################

      # Create a sortable string based on the digit strings present in an
      # enumcron string

      def self.enumcronSortString str
        rv = '0'
        str.scan(/\d+/).each do |nums|
          rv += nums.size.to_s + nums
        end
        return rv
      end

      def self.enumcronSort a,b
        matcha = /(\d{4})/.match a['enumcron']
        matchb = /(\d{4})/.match b['enumcron']
        if (matcha and matchb)
          return matcha[1] <=> matchb[1] unless (matcha[1] == matchb[1])
        end
        return a[:sortstring] <=> b[:sortstring]
      end


      # We'll take an easy way out; add a :sortstring entry to each hash, and then
      # delete them later.
      #
      # @param [Array] info An array of hashes, each of which has an 'enumcron' entry
      # @return [Arrray] the array sorted by our best guess of enumcron order

      def self.sortHathiJSON arr
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

        arr.sort! {|a,b| self.enumcronSort(a, b)}
        arr.each do |h|
          h.delete(:sortstring)
        end
        return arr
      end


      ###############################################
      # The hathitrust stuff is a disaster. Just put
      # it all in one big method and use side effects.
      #################################################

      def self.fillHathi doc, r, tmaps
        # Set some defaults
        defaultDate = '00000000'

        # Get the 974s
        fields = r.find_by_tag('974');

        # How many of them are there?
        ht_count = fields.size
        
#puts "HT_COUNT is #{ht_count}"
        # If zero, just set HTSO to false and bail. Nothing to do
        if ht_count == 0
          doc['ht_searchonly'] = false
          doc['ht_searchonly_intl'] = false
          doc['id'] = nil
          return nil
        end

        # ...otherwise, set it
        doc['ht_count'] = ht_count

        # Start off by assuming that it's HTSO for both us and intl
        htso      = true
        htso_intl = true

        # Presume no enumchron
        gotEnumchron = false


        # Places to stash things
        htids = []
        json = []
        jsonindex = {}
        avail = {:us => [], :intl => []}
        rights = []
        sources = []

        # Loop through the fields to get what we need
        fields.each do |f|

          # Get the rights code
          rc = f['r']
          rights << rc

          # Set availability based on the rights code
          us_avail = tmaps['availability_map_ht'][rc]
          intl_avail =  tmaps['availability_map_ht_intl'][rc]
          avail[:us] << us_avail
          avail[:intl] << intl_avail

          # Get the ID and make sure it's lowercase.
          # Put it in a local array (htids) because we have to return it
          id = f['u']
          lc_id = id.downcase
          if id != lc_id
            log.error "#{id} needs to be lowecase";
            id = lc_id
          end
          htids << id

          # Extract the source
          m = /^(.*?+)\./.match id
          unless m and m[1]
            log.error "Bad htid '#{id}' in record #{ r['001'].value}"
            next
          end

          sources << HTSOURCEMAP[m[1]]

          # Update date
          udate = f['d'] || defaultDate
          doc.add 'ht_id_update', udate

          # Start the json rec.
          jsonrec = {
            'htid' => id,
            'ingest' => udate,
            'rights'  => rc,
            'heldby'   => [] # fill in later
          }

          # enumchron
          echron = f['z']
          if echron
            jsonrec['enumcron'] = echron
            gotEnumchron = true
          end


          # Display
          doc.add 'ht_id_display', [id, udate, echron].join("|")

          # Add the current item's information to the json array,
          # and keep a pointer to it in jsonindex so we can easily
          # update the holdings later.

          json << jsonrec
          jsonindex[id] = jsonrec

          # Does this item already negate HTSO?
          htso = false if us_avail == 'Full Text'
          htso_intl = false if intl_avail == 'Full Text'
        end


        # Done processing the items. Add aggreage info

        # If we've got nothing in ht_rightscode but 'nobody', we
        # need to mark it as a tombstone.

        rights.uniq!    #make uniq
        rights.compact! #remove nil
      
        if rights.size == 1 && rights[0] == 'nobody'
          rights << 'tombstone'
        end


        doc.add 'ht_availability',  avail[:us].uniq
        doc.add 'ht_availability_intl', avail[:intl].uniq
        doc.add 'ht_rightscode', rights
        doc.add 'htsource', sources.uniq





        # Now we need to do record-level
        # stuff.

        # Figure out for real the HTSO status. It's only HTSO
        # if the item-level stuff is htso (as represented by htso
        # and htso_intl) AND the record_level stuff is also HTSO.

        record_htso = self.record_level_htso(r)
        doc['ht_searchonly'] = htso && record_htso
        doc['ht_searchonly_intl'] = htso_intl && record_htso

        # Add in the print database holdings

         heldby = []
         holdings = self.fromHTID(htids)
         holdings.each do |a|
           htid, inst = *a
           heldby << inst
           jsonindex[htid]['heldby'] << inst
         end
         
         doc['ht_heldby'] = heldby.uniq

        # Sort and JSONify the json structure

        json = sortHathiJSON json if gotEnumchron
        doc['ht_json'] = json.to_json

        # Finally, return the ids
        return htids

      end


      ############################################################
      # Get record-level boolean for whether or not this is HTSO
      ###########################################################
      def self.record_level_htso r
        # Check to see if we have an online or circ holding
        r.find_by_tag('973').each do |f|
          return false if f['b'] == 'avail_online';
          return false if f['b'] == 'avail_circ';
        end

        # Check to see if we have a local holding that's not SDR
        r.find_by_tag('852').each do |f|
          return false if f['b'] and f['b'] != 'SDR'
        end

        # otherwise
        return true
      end





      ########################################################
      # PRINT HOLDINGS
      ########################################################
      # Get the print holdings from the phdb, based on
      # hathitrust IDs.
      #

      # Log in

      @htidsnippet = "
        select volume_id, member_id from holdings_htitem_htmember
        where volume_id "

      def self.fromHTID htids
        Thread.current[:phdbdbh] ||= JDBCHelper::Connection.new(
          :driver=>'com.mysql.jdbc.Driver',
          :url=>'jdbc:mysql://' + MDP_DB_MACHINE + '/ht',
          :user => MDP_USER,
          :password => MDP_PASSWORD
        )

        q = @htidsnippet + "IN (#{commaify htids})"
        return Thread.current[:phdbdbh].query(q)
      end

      # Produce a comma-delimited list. We presume there aren't any double-quotes
      # in the values

      def self.commaify a
        return *a.map{|v| "\"#{v}\""}.join(', ')
      end


    end
  end
end