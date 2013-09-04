$:.unshift '/Users/dueberb/devel/ruby/ruby-marc/lib'
$:.unshift File.expand_path('../ht', __FILE__)


require 'marc/fast_xmlwriter'
require 'library_stdnums'

require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats


require_relative 'lib/ht_macros'
extend Traject::Macros::HathiTrust

 
require 'traject/debug_writer'
# require 'traject/line_writer'
# require 'traject/yaml_writer'
# require 'traject/json_writer'

require 'traject/marc4j_reader'
require 'traject/mock_writer'

settings do
  store "reader_class_name", "Traject::Marc4JReader"
  store "marc4j_reader.keep_marc4j", true
  store "writer_class_name", "Traject::DebugWriter"
  store "output_file", "debug.out"
  store "log.batch_progress", 5_000
  store 'processing_thread_pool', 0
  provide "mock_reader.limit", 100
  
end



################################
###### CORE FIELDS #############
################################

to_field "id", extract_marc("001", :first => true)


      #VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
      #******  COMMENTED OUT  
      #******  FOR TESTING ONLY
      #******  DON'T FORGET TO REENGAGE!!!

      # to_field 'fullrecord' do |record, acc| 
      #   acc << MARC::FastXMLWriter.encode(record)  
      # end

      #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

to_field "allfields", extract_all_marc_values

# Get a formatter
Traject::Util.require_marc4j_jars({})
require '/Users/dueberb/devel/java/MARCFormat/dist/MARCFormat.jar'
format_extractor = Java::org.marc4j::GetFormat.new
$:.unshift '/Users/dueberb/devel/ruby/traject/ht'
format_map       = Traject::TranslationMap.new("formats")

to_field "format" do |record, acc|
  f = format_extractor.get_content_types_and_media_types(record.original_marc4j).map{|c| format_map[c.to_s]}
  f.flatten!
  f.compact!
  f.uniq!
  acc.concat f
end
  

######## Local Data ##########
# 
# field("format") do
#   mapname 'format_map_umich'
#   spec("970a")
# end
# 
# 

# to_field 'cat_date' do 
#   catdate_spec = Traject::MarcExtractor.new('972c')
#   lambda do |record, acc|
#     last_cat = catdate_spec.extract(record).max
#     acc << last_cat if last_cat
#   end
# end


################################
######## IDENTIFIERS ###########
################################

to_field "lccn", extract_marc('010a')
to_field 'rptnum', extract_marc('088a')
to_field 'oclc', oclcnum("035a:035z")

to_field 'sdrnum', please {
  oh35a_spec = Traject::MarcExtractor.new('035a')
  lambda do |record, acc|
     oh35a_spec.extract(record).grep(/^sdr-?(.*)/)
  end
}




to_field 'isbn', please {
  isbn_spec = Traject::MarcExtractor.new('020az', :separator=>nil) # 
  lambda do |record, acc|
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
}

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
to_field 'titla',     extract_with_and_without_filing_characters('245abdefghknp', :trim_punctuation => true)
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

# custom('serialTitle') do
#   function(:getSerialTitle) {
#     mod mcu
#     args 'abdefghknp'.split(//)
#   }
# end
# 
# custom('serialTitle_ab') do
#   function(:getSerialTitle) {
#     mod mcu
#     args ['a', 'b']
#   }
# end
# 
# custom('serialTitle_a') do
#   function(:getSerialTitle) {
#     mod mcu
#     args ['a']
#   }
# end
# 
# custom('serialTitle_rest') do
#   function(:getSerialTitleRest) {
#     mod mcu
#   }
# end

################################
######## SUBJECT / TOPIC  ######
################################

to_field "topic", extract_marc("600abcdefghjklmnopqrstuvxyz:600a:610abcdefghklmnoprstuvxyz:610a:611acdefghjklnpqstuvxyz:611a:630adefghklmnoprstvxyz:630a:648avxyz:648a:650abcdevxyz:650a:651aevxyz:651a:653a:654abevyz:654a:655abvxyz:655a:656akvxyz:656a:657avxyz:657a:658ab:658a:662abcdefgh:662a:690abcdevxyz:690a", :trim_punctuation=>true)

###############################
#### Genre / geography / dates
###############################

to_field "genre", extract_marc('655ab')


# field('geographic') do
#   mapname 'area_map'
#   spec("043a")
# end

to_field 'era', extract_marc("600y:610y:611y:630y:650y:651y:654y:655y:656y:657y:690z:691y:692z:694z:695z:696z:697z:698z:699z")

# country from the 008; need processing until I fix the AlephSequential reader

# custom('country_of_pub') do
#   function(:country_of_pub) {
#     mod mcu
#   }
# end
# 
# # Also do the 752 for country of pub
# field('country_of_pub') do
#   spec("752ab")
# end
# 
# custom('publishDate') do
#   function(:getDate) {
#     mod mc
#   }
# end
# 
# custom('publishDateRange') do
#   function(:publishDateRange) {
#     mod mcu
#   }
# end
# 

################################
########### MISC ###############
################################

to_field "publisher", extract_marc('260b:533c')
to_field "edition", extract_marc('250a')

# custom('language') do
#   mapname 'language_map'
#   function(:getLanguage) {
#     mod mcu
#   }
# end


to_field 'language008', extract_marc('008[35-37]')

#####################################
############ HATHITRUST STUFF #######
#####################################
#
# The HT stuff has gotten ridiculously complex
# Needs refactoring in a big way. How many times am I going to
# find the 974s?
#
# Sadly, I can't do it *all* with side effects because the syntax demands that
# something actually get set. So, we'll set ht_id, and do everything else by
# directly manipulating the doc
# 
# custom('ht_id') do
#   function(:fillHathi) {
#     mod mcu
#     args TMAPS
#   }
# end
# 

