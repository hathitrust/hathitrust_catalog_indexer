$:.unshift  "#{File.dirname(__FILE__)}/../lib"

require 'library_stdnums'

require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

require 'ht_traject'
extend HathiTrust::Traject::Macros
extend Traject::UMichFormat::Macros

require 'naconormalizer'

# require 'dynamic_field_doc'
# extend DynamicFieldDocs

settings do
  store "log.batch_progress", 1_000
  #store 'processing_thread_pool', 0
  provide "dynamic_field_docs.output_stream", File.open('dfield_defs.txt', 'w:utf-8')
end






logger.info RUBY_DESCRIPTION

################################
###### Setup ###################
################################

# Set up an area in the clipboard for use storing intermediate stuff
each_record HathiTrust::Traject::Macros.setup



#######  COMMON STUFF BETWEEN UMICH AND HT ########
#######  INDEXING                          ########




################################
###### CORE FIELDS #############
################################

to_field "id", extract_marc("001", :first => true)

# Allfields in both regular and proper
to_field "allfields_t", extract_all_marc_values do |r, acc|
  acc.replace [acc.join(' ')] # turn it into a single string
end
to_field "allfields_tp" do |rec, acc, context|
  acc.replace context.output_hash['allfields_t']
end

to_field 'fullrecord' do |rec, acc|
  acc << MARC::FastXMLWriter.single_record_document(rec)
end

to_field 'format_s_s', umich_format_and_types



################################
######## IDENTIFIERS ###########
################################

to_field 'oclc_n_s', oclcnum('035a:035z')

sdr_pattern = /^sdr-/
to_field 'sdrnum_s_s' do |record, acc|
  oh35a_spec = Traject::MarcExtractor.cached('035a')
  acc.concat oh35a_spec.extract(record).grep(sdr_pattern)
end


# All the ISBN forms for searching
to_field 'isbn_n_s', extract_marc('020az', :separator=>nil) do |rec, acc|
     orig = acc.dup
     acc.map!{|x| StdNum::ISBN.allNormalizedValues(x)}
     #acc << orig
     acc.flatten!
     acc.uniq!
end


to_field 'issn_n_s', extract_marc('022a:022l:022m:022y:022z:247x')
to_field 'isn_related_n_s', extract_marc("400x:410x:411x:440x:490x:500x:510x:534xz:556z:581z:700x:710x:711x:730x:760x:762x:765xz:767xz:770xz:772x:773xz:774xz:775xz:776xz:777x:780xz:785xz:786xz:787xz")



to_field 'sudoc_s_s', extract_marc('086az')
to_field "lccn_s_s", extract_marc('010a')
to_field 'rptnum_e_s', extract_marc('088a')

################################
######### AUTHOR FIELDS ########
################################

# We need to skip all the 710 with a $9 == 'WaSeSS'

skipWaSeSS = ->(rec,field) { field.tag == '710' && field['9'] == 'WaSeSS' }

to_field 'mainauthor_t_s', extract_marc('100abcd:110abcd:111abc')
to_field 'mainauthor_role_t_s', extract_marc('100e:110e:111e', :trim_punctuation => true)
to_field 'mainauthor_role_t_s', extract_marc('1004:1104:1114', :translation_map => "ht/relators")


to_field 'author_tp_s', extract_marc_unless("100abcd:110abcd:111abc:700abcdt:710abcd:711abc",skipWaSeSS )
to_field 'author2_tp', extract_marc_unless("110ab:111ab:700abcd:710ab:711ab",skipWaSeSS)
to_field "author_top_tp", extract_marc_unless("100abcdefgjklnpqtu0:110abcdefgklnptu04:111acdefgjklnpqtu04:700abcdejqux034:710abcdeux034:711acdegjnqux034:720a:765a:767a:770a:772a:774a:775a:776a:777a:780a:785a:786a:787a:245c",skipWaSeSS)
to_field "author_rest_tp_s", extract_marc("505r")


# Naconormalizer for author
author_normalizer = NacoNormalizer.new
to_field "author_sort", extract_marc_unless("100abcd:110abcd:111abc:110ab:700abcd:710ab:711ab",skipWaSeSS, :first=>true) do |rec, acc, context|
  acc.map!{|a| author_normalizer.normalize(a)}
  acc.compact!
end


################################
########## TITLES ##############
################################

# For titles, we want with and without filing characters

# Display title

to_field 'title_display',  extract_marc('245abdefghknp', :trim_punctuation => true, :first=>true)

# Searchable titles

to_field 'title_tmax_s', extract_marc('245abdefghknp', :trim_punctuation => true)
to_field 'title_tmax', extract_marc_filing_version('245abdefghknp',  :include_original => false)
to_field 'title_a_e',   extract_marc_filing_version('245a', :include_original => true)
to_field 'title_ab_e',  extract_marc_filing_version('245ab', :include_original => true)
to_field 'title_c_e',   extract_marc('245c')

to_field 'vtitle_mtmax_s',    extract_marc('245abdefghknp', :alternate_script=>:only, :trim_punctuation => true)


# Sortable title
to_field "title_sort", marc_sortable_title

#title_normalizer  = NacoNormalizer.new(:keep_first_comma => false)
#to_field "title_sort_e", extract_marc_filing_version('245abk') do |rec, acc, context|
#  acc.replace [acc[0]] # get only the first one
#  acc.map!{|a| title_normalizer.normalize(a)}
#  acc.compact!
#end


to_field "title_top_tmax", extract_marc("240adfghklmnoprs0:245abfghknps:247abfghknps:111acdefgjklnpqtu04:130adfghklmnoprst0")
to_field "title_rest_tmax", extract_marc("210ab:222ab:242abhnpy:243adfghklmnoprs:246abdenp:247abdenp:700fghjklmnoprstx03:710fghklmnoprstx03:711acdefghjklnpqstux034:730adfghklmnoprstx03:740ahnp:765st:767st:770st:772st:773st:775st:776st:777st:780st:785st:786st:787st:830adfghklmnoprstv:440anpvx:490avx:505t")
to_field "series_tmax_s", extract_marc("440ap:800abcdfpqt:830ap")
to_field "series2_tmax", extract_marc("490a")
#
## Serial titles count on the format already being set and having the string 'Serial' in it.
#
each_record do |rec, context|
  context.clipboard[:ht][:journal] = true if context.output_hash['format_s_s'].include? 'Serial'
end

to_field "serial_title_tmax_s" do |r, acc, context|
  if context.clipboard[:ht][:journal]
    acc.replace Array(context.output_hash['title_tmax_s'])
  end
end

to_field('serialTitle_ab_tmax') do |r, acc, context|
  if context.clipboard[:ht][:journal]
    acc.replace Array(context.output_hash['title_ab_tmax_s'])
  end
end

to_field('serialTitle_top_tmax') do |r, acc, context|
  if context.clipboard[:ht][:journal]
    acc.replace Array(context.output_hash['title_top_tmax'])
  end
end

to_field('serialTitle_rest_tmax') do |r, acc, context|
  if context.clipboard[:ht][:journal]
    acc.replace Array(context.output_hash['title_rest_tmax'])
  end
end

#################################
######### SUBJECT / TOPIC  ######
#################################
#
## We get the full topic (LCSH), but currently want to ignore
## entries that are FAST entries (those having second-indicator == 7)
#
#
skip_FAST = ->(rec,field) do
  field.indicator2 == '7'
end

to_field "topic_s", extract_marc_unless(%w(
  600a  600abcdefghjklmnopqrstuvxyz
  610a  610abcdefghklmnoprstuvxyz
  611a  611acdefghjklnpqstuvxyz
  630a  630adefghklmnoprstvxyz
  648a  648avxyz
  650a  650abcdevxyz
  651a  651aevxyz
  653a  653abevyz
  654a  654abevyz
  655a  655abvxyz
  656a  656akvxyz
  657a  657avxyz
  658a  658ab
  662a  662abcdefgh
  690a   690abcdevxyz
  ), skip_FAST, :trim_punctuation=>true)

# Again, but this time put into a path-type, delimited with pipes

to_field "topic_pp_s", extract_marc_unless(%w(
  600abcdefghjklmnopqrstuvxyz
  610abcdefghklmnoprstuvxyz
  611acdefghjklnpqstuvxyz
  630adefghklmnoprstvxyz
  648avxyz
  650abcdevxyz
  651aevxyz
  653abevyz
  654abevyz
  655abvxyz
  656akvxyz
  657avxyz
  658ab
  662abcdefgh
  690abcdevxyz
  ), skip_FAST, :trim_punctuation=>true, :separator => '|')

################################
##### Genre / geography / dates
################################
#
to_field "genre_e_s", extract_marc('655ab')


# Look into using Traject default geo field
to_field "geographic_t_s" do |record, acc|
  marc_geo_map = Traject::TranslationMap.new("marc_geographic")
  extractor_043a  = MarcExtractor.cached("043a", :separator => nil)
  acc.concat(
    extractor_043a.extract(record).collect do |code|
      # remove any trailing hyphens, then map
      marc_geo_map[code.gsub(/\-+\Z/, '')]
    end.compact
  )
end

to_field 'era_s_s', extract_marc("600y:610y:611y:630y:650y:651y:654y:655y:656y:657y:690z:691y:692z:694z:695z:696z:697z:698z:699z")

## country from the 008; need processing until I fix the AlephSequential reader
#
to_field "country_of_pub_t_s" do |r, acc|
  country_map = Traject::TranslationMap.new("ht/country_map")
  if r['008']
    [r['008'].value[15..17], r['008'].value[17..17]].each do |s|
      next unless s # skip if the 008 just isn't long enough
      country = country_map[s.gsub(/[^a-z]/, '')]
      acc << country if country
    end
  end
end

# Also add the 752ab
to_field "country_of_pub_t_s", extract_marc('752ab')
#
## Deal with the dates
#
## First, find the date and put it into context.clipboard[:ht_date] for later use
each_record extract_date_into_context
#
## Now use that value
to_field "publishDate_s_s", get_date
to_field 'pub_date', get_date
#
to_field 'publishDateRange_s_s' do |rec, acc, context|
  if context.output_hash['publishDate_s_s']
    d =  context.output_hash['publishDate_s_s'].first
    dr = HathiTrust::Traject::Macros::HTMacros.compute_date_range(d)
    acc << dr if dr
  else
    if context.output_hash['id']
      id = context.output_hash['id'].first
    else
      id = "<no id in record>"
    end
    logger.debug "No valid date for record #{id}: #{rec['008']}"
  end
end
#
#
#################################
############ MISC ###############
#################################
#
to_field "publisher_t_s", extract_marc('260b:264|*1|:533c')
to_field "edition_t_s", extract_marc('250a')

to_field 'language_s_s', marc_languages("008[35-37]:041a:041d:041e:041j")
to_field 'language008_s', extract_marc('008[35-37]') do |r, acc|
  acc.reject! {|x| x !~ /\S/} # ditch only spaces
  acc.uniq!
end

to_field "physical_description", extract_marc('300abcdefghijklmnopqrstuvwxyz012345789')
