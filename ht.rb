$:.unshift '/Users/dueberb/devel/ruby/ruby-marc/lib'
$:.unshift  "#{File.dirname(__FILE__)}/lib"

require 'marc/fast_xmlwriter'
require 'marc/nokogiri_writer'
require 'library_stdnums'

require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats


require 'ht_macros'
require 'ruby_marc_to_marc4j'
require 'ht_item'
extend HathiTrust::Traject::Macros

 
require 'traject/marc4j_reader'
require 'traject/mock_reader'
require 'traject/mock_writer'
require 'traject/debug_writer'

settings do
  store "reader_class_name", "Traject::Marc4JReader"
  store "marc4j_reader.keep_marc4j", true
  provide "mock_reader.limit", 100
  
  provide "solr.url", "http://mojito.umdl.umich.edu:8024/solr/biblio"
  provide "solrj_writer.parser_class_name", "XMLResponseParser"
  provide "solrj_writer.commit_on_close", "true"
  
  store "writer_class_name", "Traject::SolrJWriter"
  store "output_file", "debug.out"
  
  store "log.batch_progress", 5_000
  
  store 'processing_thread_pool', 0
  
end

# Get ready to map marc4j record into an xml string
unless defined?(MarcPermissiveStreamReader) && defined?(MarcXmlReader)
  Traject::Util.require_marc4j_jars(settings)
end

################################
###### Setup ###################
################################

# Set up an area in the clipboard for use storing intermediate stuff
each_record HathiTrust::Traject::Macros.setup


# Get a marc4j record if we don't have one already
marc_converter = HathiTrust::MARC2MARC4J.new({})
each_record do |rec|
  rec.original_marc4j ||= marc_converter.convert_to_marc4j(rec)
end


################################
###### CORE FIELDS #############
################################

to_field "id", extract_marc("001", :first => true)
to_field 'fullrecord', macr4j_as_xml
to_field "allfields", extract_all_marc_values

# Get a formatter
require 'MARCFormat.jar'
format_extractor = Java::org.marc4j::GetFormat.new
format_map       = Traject::TranslationMap.new("formats")

to_field "format" do |record, acc, context|
  f = format_extractor.get_content_types_and_media_types(record.original_marc4j).map{|c| format_map[c.to_s]}
  f.flatten!
  f.compact!
  f.uniq!
  acc.concat f
  
  # We need to know for later if this is a serial/journal type
  if acc.include? "Journal"
    context.clipboard[:ht][:journal] = true
  end
end

  

################################
######## IDENTIFIERS ###########
################################

to_field "lccn", extract_marc('010a')
to_field 'rptnum', extract_marc('088a')
to_field 'oclc', oclcnum("035a:035z")

to_field 'sdrnum' do |record, acc|
  oh35a_spec = Traject::MarcExtractor.cached('035a')
  oh35a_spec.extract(record).grep(/^sdr-?(.*)/)
end



to_field 'isbn' do |record, acc|
  isbn_spec = Traject::MarcExtractor.cached('020az', :separator=>nil) # 
  vals = []
  isbn_spec.extract(record).each do |v|
    std = StdNum::ISBN.allNormalizedValues(v)
    if std.size > 0
      vals.concat std
    else
      vals << v
    end
  end
  vals.uniq! # If it already has both a 10 and a 13, each will have generated the other
  acc.concat vals
end

to_field 'issn', extract_marc('022a:022l:022m:022y:022z:247x')
to_field 'isn_related', extract_marc("400x:410x:411x:440x:490x:500x:510x:534xz:556z:581z:700x:710x:711x:730x:760x:762x:765xz:767xz:770xz:772x:773xz:774xz:775xz:776xz:777x:780xz:785xz:786xz:787xz")
to_field 'callnumber', extract_marc('050ab:090ab')
to_field 'callnoletters', extract_marc('050ab:090ab', :first=>true)
to_field 'sudoc', extract_marc('086az')

################################
######### AUTHOR FIELDS ########
################################

to_field 'mainauthor', extract_marc('100abcd:110abcd:111abc')
to_field 'author', extract_marc("100abcd:110abcd:111abc:700abcd:710abcd:711abc")
to_field 'author2', extract_marc("110ab:111ab:700abcd:710ab:711ab")
to_field "authorSort", extract_marc("100abcd:110abcd:111abc:110ab:700abcd:710ab:711ab")
to_field "author_top", extract_marc("100abcdefgjklnpqtu0:110abcdefgklnptu04:111acdefgjklnpqtu04:700abcdejqux034:710abcdeux034:711acdegjnqux034:720a:765a:767a:770a:772a:774a:775a:776a:777a:780a:785a:786a:787a:245c")
to_field "author_rest", extract_marc("505r")


################################
########## TITLES ##############
################################

# For titles, we want with and without
to_field 'title',     extract_with_and_without_filing_characters('245abdefghknp', :trim_punctuation => true)
to_field 'title_a',   extract_with_and_without_filing_characters('245a', :trim_punctuation => true)
to_field 'title_ab',  extract_with_and_without_filing_characters('245ab', :trim_punctuation => true)
to_field 'title_c',   extract_marc('245c')
to_field 'vtitle',    extract_marc('245abdefghknp', :alternate_script=>:only)
to_field 'title',     extract_marc('245')

# Sortable title
to_field "titleSort", marc_sortable_title


to_field "title_top", extract_marc("240adfghklmnoprs0:245abfghknps:247abfghknps:111acdefgjklnpqtu04:130adfghklmnoprst0")
to_field "title_rest", extract_marc("210ab:222ab:242abhnpy:243adfghklmnoprs:246abdenp:247abdenp:700fghjklmnoprstx03:710fghklmnoprstx03:711acdefghjklnpqstux034:730adfghklmnoprstx03:740ahnp:765st:767st:770st:772st:773st:775st:776st:777st:780st:785st:786st:787st:830adfghklmnoprstv:440anpvx:490avx:505t")
to_field "series", extract_marc("440ap:800abcdfpqt:830ap")
to_field "series2", extract_marc("490a")

# Serial titles count on the format alreayd being set and having the string 'Serial' in it.

to_field "serialTitle" do |r, acc, context|
  if context.clipboard[:ht][:journal]
    extract_with_and_without_filing_characters('245abdefghknp', :trim_punctuation => true).call(r, acc, context)
  end
end

to_field('serialTitle_ab') do |r, acc, context|
  if context.clipboard[:ht][:journal]
    extract_with_and_without_filing_characters('245ab', :trim_punctuation => true).call(r, acc, context)
  end
end  

to_field('serialTitle_a') do |r, acc, context|
  if context.clipboard[:ht][:journal]
    extract_with_and_without_filing_characters('245a', :trim_punctuation => true).call(r, acc, context)
  end
end  
  
to_field('serialTitle_rest') do |r, acc, context|
  if context.clipboard[:ht][:journal]
    extract_with_and_without_filing_characters(%w[
      130adfgklmnoprst
      210ab
      222ab
      240adfgklmnprs
      246abdenp
      247abdenp
      730anp
      740anp
      765st
      767st
      770st
      772st
      775st
      776st
      777st
      780st
      785st
      786st
      787st  
    ], :trim_punctuation => true).call(r, acc, context)
  end
end  



################################
######## SUBJECT / TOPIC  ######
################################

to_field "topic", extract_marc("600abcdefghjklmnopqrstuvxyz:600a:610abcdefghklmnoprstuvxyz:610a:611acdefghjklnpqstuvxyz:611a:630adefghklmnoprstvxyz:630a:648avxyz:648a:650abcdevxyz:650a:651aevxyz:651a:653a:654abevyz:654a:655abvxyz:655a:656akvxyz:656a:657avxyz:657a:658ab:658a:662abcdefgh:662a:690abcdevxyz:690a", :trim_punctuation=>true)

###############################
#### Genre / geography / dates
###############################

to_field "genre", extract_marc('655ab')


# Look into using Traject default geo field
to_field "geographic" do |record, acc|
  marc_geo_map = Traject::TranslationMap.new("marc_geographic")
  extractor_043a      = MarcExtractor.cached("043a", :seperator => nil)
  acc.concat(
    extractor_043a.extract(record).collect do |code|
      # remove any trailing hyphens, then map
      marc_geo_map[code.gsub(/\-+\Z/, '')]
    end.compact
  )
end

to_field 'era', extract_marc("600y:610y:611y:630y:650y:651y:654y:655y:656y:657y:690z:691y:692z:694z:695z:696z:697z:698z:699z")

# country from the 008; need processing until I fix the AlephSequential reader

to_field "country_of_pub" do |r, acc|
  country_map = Traject::TranslationMap.new("country_map")
  if r['008']
    [r['008'].value[15..17], r['008'].value[17..17]].each do |s|
      country = country_map[s.gsub(/[^a-z]/, '')]
      acc << country if country
    end
  end
end

# Also add the 752ab  
to_field "country_of_pub", extract_marc('752ab')

# Deal with the dates

# First, find the date and put it into context.clipboard[:ht_date] for later use
each_record extract_date_into_context

# Now use that value
to_field "publishDate" do |record, acc, context|
  if context.clipboard[:ht][:date]
    acc << context.clipboard[:ht][:date] 
  else
    logger.debug "No valid date: #{record['001'].value}"
  end
end

to_field 'publishDateRange' do |rec, acc, context|
   dr = HathiTrust::Traject::Macros::HTMacros.compute_date_range(context.clipboard[:ht][:date])
   acc << dr if dr
 end


################################
########### MISC ###############
################################

to_field "publisher", extract_marc('260b:533c')
to_field "edition", extract_marc('250a')

to_field 'language', marc_languages("008[35-37]:041a:041d:041e:041j")
to_field 'language008', extract_marc('008[35-37]')

#####################################
############ HATHITRUST STUFF #######
#####################################
#


# Start off by building up a data structure representing all the 974s
# and stick it in ht_fields
each_record do |r, context|
  
  itemset = HathiTrust::Traject::ItemSet.new
  
  r.each_by_tag('974') do |f|
    itemset.add HathiTrust::Traject::Item.new_from_974(f)
  end
  
  if itemset.size == 0
    # context.skip!("No 974s in record  #{r['001']}")
  end
  context.clipboard[:ht][:items] = itemset
    
end


to_field 'ht_count' do |record, acc, context|
  acc << context.clipboard[:ht][:items].size
end

to_field 'ht_id' do |record, acc, context|
  acc << context.clipboard[:ht][:items].ht_ids
end

to_field 'ht_rightscode' do |record, acc, context|
  acc.concat context.clipboard[:ht][:items].rights_list
end

to_field 'ht_availability' do |record, acc, context|
  acc.concat context.clipboard[:ht][:items].us_availability
end

to_field 'ht_availability_intl' do |record, acc, context|
  acc.concat context.clipboard[:ht][:items].intl_availability
end

to_field 'htsource' do |record, acc, context|
  acc.concat context.clipboard[:ht][:items].sources
end

to_field 'ht_id_update' do |record, acc, context|
  acc.concat context.clipboard[:ht][:items].last_update_dates
end

to_field 'ht_id_display' do |record, acc, context|
  context.clipboard[:ht][:items].each do |item|
    acc << item.display_string
  end
end

to_field 'ht_searchonly' do |record, acc, context|
  acc << context.clipboard[:ht][:items].us_fulltext? ? 'false' : 'true'
end

to_field 'ht_searchonly_intl' do |record, acc, context|
  acc << context.clipboard[:ht][:items].intl_fulltext? ? 'false' : 'true'
end

# Get the list of holding institutions and stash it

# Use the list of holding instituions

# Now have enough information to build the ht_json object






# 
#         # Start off by assuming that it's HTSO for both us and intl
#         htso      = true
#         htso_intl = true
# 
#         # Presume no enumchron
#         gotEnumchron = false
# 
# 
#         # Places to stash things
#         htids = []
#         json = []
#         jsonindex = {}
#         avail = {:us => [], :intl => []}
#         rights = []
#         sources = []
# 
#         # Loop through the fields to get what we need
#         fields.each do |f|
# 
        #           # Get the rights code
        #           rc = f['r']
        #           rights << rc
        # 
        #           # Set availability based on the rights code
        #           us_avail = tmaps['availability_map_ht'][rc]
        #           intl_avail =  tmaps['availability_map_ht_intl'][rc]
        #           avail[:us] << us_avail
        #           avail[:intl] << intl_avail
        # 
        #           # Get the ID and make sure it's lowercase.
        #           # Put it in a local array (htids) because we have to return it
        #           id = f['u']
        #           lc_id = id.downcase
        #           if id != lc_id
        #             log.error "#{id} needs to be lowecase";
        #             id = lc_id
        #           end
        #           htids << id
        # 
        # 
        #           sources << HTSOURCEMAP[m[1]]
        # 
        #           # Update date
        #           udate = f['d'] || defaultDate
        #           doc.add 'ht_id_update', udate
# 
#           # Start the json rec.
#           jsonrec = {
#             'htid' => id,
#             'ingest' => udate,
#             'rights'  => rc,
#             'heldby'   => [] # fill in later
#           }
# 
#           # enumchron
#           echron = f['z']
#           if echron
#             jsonrec['enumcron'] = echron
#             gotEnumchron = true
#           end
# 
# 
        #           # Display
        #           doc.add 'ht_id_display', [id, udate, echron].join("|")
# 
#           # Add the current item's information to the json array,
#           # and keep a pointer to it in jsonindex so we can easily
#           # update the holdings later.
# 
#           json << jsonrec
#           jsonindex[id] = jsonrec
# 
#           # Does this item already negate HTSO?
#           htso = false if us_avail == 'Full Text'
#           htso_intl = false if intl_avail == 'Full Text'
#         end
# 
# 
        #         # Done processing the items. Add aggreage info
        # 
        #         # If we've got nothing in ht_rightscode but 'nobody', we
        #         # need to mark it as a tombstone.
        # 
        #         rights.uniq!    #make uniq
        #         rights.compact! #remove nil
        #       
        #         if rights.size == 1 && rights[0] == 'nobody'
        #           rights << 'tombstone'
        #         end
        # 
        # 
        #         doc.add 'ht_availability',  avail[:us].uniq
        #         doc.add 'ht_availability_intl', avail[:intl].uniq
        #         doc.add 'ht_rightscode', rights
        #         doc.add 'htsource', sources.uniq
        # 
        # 
        # 
        # 
        # 
#         # Now we need to do record-level
#         # stuff.
# 
#         # Figure out for real the HTSO status. It's only HTSO
#         # if the item-level stuff is htso (as represented by htso
#         # and htso_intl) AND the record_level stuff is also HTSO.
# 
#         record_htso = self.record_level_htso(r)
#         doc['ht_searchonly'] = htso && record_htso
#         doc['ht_searchonly_intl'] = htso_intl && record_htso
# 
#         # Add in the print database holdings
# 
#          heldby = []
#          holdings = self.fromHTID(htids)
#          holdings.each do |a|
#            htid, inst = *a
#            heldby << inst
#            jsonindex[htid]['heldby'] << inst
#          end
#          
#          doc['ht_heldby'] = heldby.uniq
# 
#         # Sort and JSONify the json structure
# 
#         json = sortHathiJSON json if gotEnumchron
#         doc['ht_json'] = json.to_json
# 
#         # Finally, return the ids
#         return htids
# 
#       end
# 
# 
#       ############################################################
#       # Get record-level boolean for whether or not this is HTSO
#       ###########################################################
#       def self.record_level_htso r
#         # Check to see if we have an online or circ holding
#         r.find_by_tag('973').each do |f|
#           return false if f['b'] == 'avail_online';
#           return false if f['b'] == 'avail_circ';
#         end
# 
#         # Check to see if we have a local holding that's not SDR
#         r.find_by_tag('852').each do |f|
#           return false if f['b'] and f['b'] != 'SDR'
#         end
# 
#         # otherwise
#         return true
#       end
# 
# 
# 
# 
# 
#       ########################################################
#       # PRINT HOLDINGS
#       ########################################################
#       # Get the print holdings from the phdb, based on
#       # hathitrust IDs.
#       #
# 
#       # Log in
# 
#       @htidsnippet = "
#         select volume_id, member_id from holdings_htitem_htmember
#         where volume_id "
# 
#       def self.fromHTID htids
#         Thread.current[:phdbdbh] ||= JDBCHelper::Connection.new(
#           :driver=>'com.mysql.jdbc.Driver',
#           :url=>'jdbc:mysql://' + MDP_DB_MACHINE + '/ht',
#           :user => MDP_USER,
#           :password => MDP_PASSWORD
#         )
# 
#         q = @htidsnippet + "IN (#{commaify htids})"
#         return Thread.current[:phdbdbh].query(q)
#       end
# 
#       # Produce a comma-delimited list. We presume there aren't any double-quotes
#       # in the values
# 
#       def self.commaify a
#         return *a.map{|v| "\"#{v}\""}.join(', ')
#       end
