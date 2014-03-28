$:.unshift  "#{File.dirname(__FILE__)}/../lib"

require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

require 'ht_traject'
extend HathiTrust::Traject::Macros
extend Traject::UMichFormat::Macros

require 'naconormalizer'


settings do
  store "log.batch_progress", 10_000
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
to_field "allfields", extract_all_marc_values do |r, acc|
  acc.replace [acc.join(' ')] # turn it into a single string
end

# to_field 'fullrecord', macr4j_as_xml

to_field 'fullrecord' do |rec, acc|
  acc << MARC::FastXMLWriter.single_record_document(rec)
end

to_field 'format', umich_format_and_types

  

################################
######## IDENTIFIERS ###########
################################

to_field 'oclc', oclcnum('035a:035z')

sdr_pattern = /^sdr-/
to_field 'sdrnum' do |record, acc|
  oh35a_spec = Traject::MarcExtractor.cached('035a')
  acc.concat oh35a_spec.extract(record).grep(sdr_pattern)
end


to_field 'isbn', extract_marc('020az', :separator=>nil)
to_field 'issn', extract_marc('022a:022l:022m:022y:022z:247x')
to_field 'isn_related', extract_marc("400x:410x:411x:440x:490x:500x:510x:534xz:556z:581z:700x:710x:711x:730x:760x:762x:765xz:767xz:770xz:772x:773xz:774xz:775xz:776xz:777x:780xz:785xz:786xz:787xz")

to_field 'callnumber', extract_marc('050ab:090ab')
to_field 'callnoletters', extract_marc('050ab:090ab', :first=>true) do |rec, acc|
  unless acc.empty?
    m = /\A([A-Za-z]+)/.match(acc[0])
    acc[0] = m[1] if m
  end
end
  
to_field 'sudoc', extract_marc('086az')
to_field "lccn", extract_marc('010a')
to_field 'rptnum', extract_marc('088a')

################################
######### AUTHOR FIELDS ########
################################

# We need to skip all the 710 with a $9 == 'WaSeSS'

skipWaSeSS = ->(rec,field) { field.tag == '710' && field['9'] == 'WaSeSS' }

to_field 'mainauthor', extract_marc_unless('100abcd:110abcd:111abc',skipWaSeSS)
to_field 'author', extract_marc_unless("100abcd:110abcd:111abc:700abcd:710abcd:711abc",skipWaSeSS )
to_field 'author2', extract_marc_unless("110ab:111ab:700abcd:710ab:711ab",skipWaSeSS)
to_field "author_top", extract_marc_unless("100abcdefgjklnpqtu0:110abcdefgklnptu04:111acdefgjklnpqtu04:700abcdejqux034:710abcdeux034:711acdegjnqux034:720a:765a:767a:770a:772a:774a:775a:776a:777a:780a:785a:786a:787a:245c",skipWaSeSS)
to_field "author_rest", extract_marc("505r")


# Naconormalizer for author
author_normalizer = NacoNormalizer.new
to_field "authorSort", extract_marc_unless("100abcd:110abcd:111abc:110ab:700abcd:710ab:711ab",skipWaSeSS, :first=>true) do |rec, acc, context|
  acc.map!{|a| author_normalizer.normalize(a)}
  acc.compact!  
end


################################
########## TITLES ##############
################################

# For titles, we want with and without

to_field 'title',     extract_marc_filing_version('245abdefghknp', :include_original => true)
to_field 'title_a',   extract_marc_filing_version('245a', :include_original => true)
to_field 'title_ab',  extract_marc_filing_version('245ab', :include_original => true)
to_field 'title_c',   extract_marc('245c')

to_field 'vtitle',    extract_marc('245abdefghknp', :alternate_script=>:only, :trim_punctuation => true, :first=>true)


# Sortable title
to_field "titleSort", marc_sortable_title
#title_normalizer  = NacoNormalizer.new(:keep_first_comma => false)
#to_field "titleSort", extract_marc_filing_version('245abk') do |rec, acc, context|
#  acc.replace [acc[0]] # get only the first one
#  acc.map!{|a| title_normalizer.normalize(a)}
#  acc.compact!
#end


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

# We get the full topic (LCSH), but currently want to ignore
# entries that are FAST entries (those having second-indicator == 7)


skip_FAST = ->(rec,field) do
  field.indicator2 == '7'
end
  
to_field "topic", extract_marc_unless(%w(
  600a  600abcdefghjklmnopqrstuvxyz
  610a  610abcdefghklmnoprstuvxyz
  611a  611acdefghjklnpqstuvxyz
  630a  630adefghklmnoprstvxyz
  648a  648avxyz
  650a  650abcdevxyz
  651a  651aevxyz
  653a  654abevyz
  654a  655abvxyz
  655a  656akvxyz
  656a  657avxyz
  657a  658ab
  658a  662abcdefgh
  690a   690abcdevxyz
  ), skip_FAST, :trim_punctuation=>true)
      

###############################
#### Genre / geography / dates
###############################

to_field "genre", extract_marc('655ab')


# Look into using Traject default geo field
to_field "geographic" do |record, acc|
  marc_geo_map = Traject::TranslationMap.new("marc_geographic")
  extractor_043a  = MarcExtractor.cached("043a", :separator => nil)
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
to_field "country_of_pub", extract_marc('752ab')

# Deal with the dates

# First, find the date and put it into context.clipboard[:ht_date] for later use
each_record extract_date_into_context

# Now use that value
to_field "publishDate", get_date

to_field 'publishDateRange' do |rec, acc, context|
  if context.output_hash['publishDate']
    d =  context.output_hash['publishDate'].first
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


################################
########### MISC ###############
################################

to_field "publisher", extract_marc('260b:264|*1|:533c')
to_field "edition", extract_marc('250a')

to_field 'language', marc_languages("008[35-37]:041a:041d:041e:041j")
to_field 'language008', extract_marc('008[35-37]') do |r, acc|
  acc.reject! {|x| x !~ /\S/} # ditch only spaces
  acc.uniq!
end







