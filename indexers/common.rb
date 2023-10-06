$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'set'
require 'library_stdnums'
require 'traject/macros/marc21_semantics'

# Need to monkey-patch extract_marc_filing_version to deal with records
# where ind2 > str.length
#
# Gotta submit a PR

module Traject::Macros::Marc21SemanticsExtensions
  class << self
    #alias old_filing_version filing_version

    def filing_version(field, str, spec)
      return str if field.is_a? MARC::ControlField

      ind2 = field.indicator2.to_i
      return str if ind2 > str.length

      super(field, str, spec)
    end
  end
end

module Traject::Macros::Marc21Semantics
  prepend Traject::Macros::Marc21SemanticsExtensions
end

extend Traject::Macros::Marc21Semantics

require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

require 'ht_traject'
extend HathiTrust::Traject::Macros
extend Traject::UMichFormat::Macros

require 'ht_traject/basic_macros'
extend HathiTrust::BasicMacros

require "ht_traject/oclc_resolution"
require 'ht_traject/redirects'
require 'marc/fastxmlwriter'
require 'marc_record_speed_monkeypatch'

settings do
  store 'log.batch_progress', 10_000
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

to_field 'id', extract_marc('001', first: true)

to_field 'old_ids' do |_rec, acc, context|
  id = context.output_hash['id'].first
  acc.replace HathiTrust::Services[:redirects].old_ids_for(id)
end

to_field 'allfields', extract_all_marc_values do |_r, acc|
  acc.replace [acc.join(' ')] # turn it into a single string
end

# to_field 'fullrecord', macr4j_as_xml

to_field 'fullrecord' do |rec, acc|
  acc << MARC::FastXMLWriter.single_record_document(rec, include_namespace: true)
end

to_field 'format', umich_format_and_types

################################
######## IDENTIFIERS ###########
################################

# to_field 'oclc', oclcnum('035a:035z')
#
#changed_by_oclc_concordance = Yell.new do |l|
#  l.adapter :file, 'changed_by_oclc_concordance', format: '%m'
#end

to_field 'oclc', oclcnum('035a:035z')

oclc_extractor = oclcnum('035a')
to_field 'oclc_search' do |rec, acc, context|
  oclc_extractor.call(rec, acc) # side-effects the acc
  original_count = acc.size
  acc.map! { |x| x.sub(/\A0+/, '') } # drop leading zeros
  acc.replace HathiTrust::OCLCResolution.all_resolved_oclcs(acc)
  if acc.size != original_count
    id = context.output_hash['id'].first
  end
end

sdr_pattern = /^sdr-/
to_field 'sdrnum' do |record, acc|
  oh35a_spec = Traject::MarcExtractor.cached('035a')
  acc.concat oh35a_spec.extract(record).grep(sdr_pattern)
end

to_field 'isbn', extract_marc('020az', separator: nil) do |_rec, acc|
  orig = acc.dup
  acc.map! { |x| StdNum::ISBN.allNormalizedValues(x) }
  acc << orig
  acc.flatten!
  acc.uniq!
end

to_field 'issn', extract_marc('022a:022l:022m:022y:022z:247x')
to_field 'isn_related', extract_marc('400x:410x:411x:440x:490x:500x:510x:534xz:556z:581z:700x:710x:711x:730x:760x:762x:765xz:767xz:770xz:772x:773xz:774xz:775xz:776xz:777x:780xz:785xz:786xz:787xz')

to_field 'sudoc', extract_marc('086az')

# UC started sending me leading spaces, so I need to do something
# about it.
to_field 'lccn', extract_marc('010a') do |_rec, acc|
  acc.map! { |x| x.strip }
end

to_field 'rptnum', extract_marc('088a')

to_field 'barcode', extract_marc('974a')

################################
######### AUTHOR FIELDS ########
################################

# We need to skip all the 710 with a $9 == 'WaSeSS'

skipWaSeSS = ->(_rec, field) { field.tag == '710' and field['9'] =~ /WaSeSS/ }

to_field 'mainauthor', extract_marc('100abcd:110abcd:111abc')
to_field 'mainauthor_role', extract_marc('100e:110e:111e', trim_punctuation: true)
to_field 'mainauthor_role', extract_marc('1004:1104:1114', translation_map: 'ht/relators')
to_field 'mainauthor_just_name', extract_marc('100abc:110abc:111abc')

to_field 'author', extract_marc_unless("100abcdjq:110abcd:111acden:700abcdjq:710abcd:711acden", skipWaSeSS)
to_field 'author2', extract_marc_unless('110ab:111ab:700abcd:710ab:711ab', skipWaSeSS)
to_field 'author_top', extract_marc_unless('100abcdefgjklnpqtu0:110abcdefgklnptu04:111acdefgjklnpqtu04:700abcdejqux034:710abcdeux034:711acdegjnqux034:720a:765a:767a:770a:772a:774a:775a:776a:777a:780a:785a:786a:787a:245c', skipWaSeSS)
to_field 'author_rest', extract_marc('505r')

to_field 'authorSort', extract_marc_unless('100abcd:110abcd:111abc:110ab:700abcd:710ab:711ab', skipWaSeSS, first: true), naconormalize, compress_spaces, strip

to_field 'author_sortkey', extract_marc_unless('100abcd:110abcd:111abc:110ab:700abcd:710ab:711ab', skipWaSeSS), first_only, naconormalize, trim_punctuation, compress_spaces, strip, downcase

################################
########## TITLES ##############
################################

# For titles, we want with and without

to_field 'title', extract_marc_filing_version('245abdekfgnp:245knp', include_original: true), first_only, strip, trim_punctuation
to_field 'title_a', extract_marc_filing_version('245a:245knp', include_original: true), first_only, strip, trim_punctuation
to_field 'title_ab', extract_marc_filing_version('245ab:245knp', include_original: true), first_only, strip, trim_punctuation
to_field 'title_c', extract_marc('245c'), strip, trim_punctuation

to_field 'vtitle', extract_marc('245abkdefgnp:245knpc', alternate_script: :only), first_only, strip, trim_punctuation

to_field 'title_top', extract_marc('240adfghklmnoprs0:245abfgknps:247abfgknps:111acdefgjklnpqtu04:130adfgklmnoprst0')
to_field 'title_rest', extract_marc('210ab:222ab:242abnpy:243adfgklmnoprs:246abdenp:247abdenp:700fgjklmnoprstx03:710fgklmnoprstx03:711acdefgjklnpqstux034:730adfgklmnoprstx03:740anp:765st:767st:770st:772st:773st:775st:776st:777st:780st:785st:786st:787st:830adfgklmnoprstv:440anpvx:490avx:505t')
to_field 'series', extract_marc('440ap:800abcdfpqt:830ap')
to_field 'series2', extract_marc('490a')

# Display, stored here for use by LSS
#

extractor_vtitle_display = MarcExtractor.cached('245abnpc:245knpc', alternate_script: :only)

to_field 'title_display', extract_marc('245abnpc:245knpc', alternate_script: false), first_only, trim_punctuation do |rec, acc, _context|
  vtitle = extractor_vtitle_display.extract(rec).first

  acc.first << " (#{Traject::Macros::Marc21.trim_punctuation(vtitle).strip})" if vtitle
end

# Sortable title

to_field 'titleSort', extract_marc_filing_version('245abnp:245knp', include_original: false), strip, trim_punctuation, first_only
to_field 'title_sortkey', extract_marc_filing_version('245abnp:245knp'), first_only, depunctuate, compress_spaces, strip, downcase

# Serial titles count on the format alreayd being set and having the string 'Serial' in it.

each_record do |_rec, context|
  context.clipboard[:ht][:journal] = true if context.output_hash['format'].include? 'Serial'
end

to_field 'serialTitle' do |_r, acc, context|
  acc.replace Array(context.output_hash['title']) if context.clipboard[:ht][:journal]
end

to_field('serialTitle_ab') do |_r, acc, context|
  acc.replace Array(context.output_hash['title_ab']) if context.clipboard[:ht][:journal]
end

to_field('serialTitle_a') do |_r, acc, context|
  acc.replace Array(context.output_hash['title_a']) if context.clipboard[:ht][:journal]
end

to_field('serialTitle_rest') do |_r, acc, context|
  acc.replace Array(context.output_hash['title_rest']) if context.clipboard[:ht][:journal]
end


###############################
#### Genre / geography / dates
###############################

to_field 'genre', extract_marc('655ab')

# Look into using Traject default geo field
to_field 'geographic' do |record, acc|
  marc_geo_map = Traject::TranslationMap.new('marc_geographic')
  extractor_043a = MarcExtractor.cached('043a', separator: nil)
  acc.concat(extractor_043a.extract(record).collect do |code|
    # remove any trailing hyphens, then map
    marc_geo_map[code.gsub(/\-+\Z/, '')]
  end.compact
  )
end

to_field 'era', extract_marc('600y:610y:611y:630y:650y:651y:654y:655y:656y:657y:690z:691y:692z:694z:695z:696z:697z:698z:699z')

# country from the 008; need processing until I fix the AlephSequential reader
to_field 'country_of_pub' do |r, acc|
  country_map = Traject::TranslationMap.new('ht/country_map')
  if r['008']
    [r['008'].value[15..17], r['008'].value[17..17]].each do |s|
      next unless s # skip if the 008 just isn't long enough

      country = country_map[s.gsub(/[^a-z]/, '')]
      acc << country if country
    end
  end
end

# Also add the 752ab
to_field 'country_of_pub', extract_marc('752ab')

# For the more-stringent "place_of_publication", we'll take
# only from the 008, and only those things that can be
# resolved in the current_cop or obsolete_cop translation
# maps, derived from the (misnamed) file at http://www.loc.gov/standards/codelists/countries.xml
#
# Several countries have one-letter codes that appear in character 17 of the 008
# (u=United States, c=Canada, etc.). Any hits on these (which are in the translation
# map as xxu, xxc, etc) will be listed as a two-fer:
#
#  uca => [United States, United States -- California ]
#
# Furthermore, we'll also special-case the USSR, since it doesn't so much
# exist anymore. Any three-letter code that ends in 'r' will be give
# the 'S.S.R' predicate iff the two-letter prefix doesn't exist in the
# current_cop.yaml file

to_field 'place_of_publication' do |r, acc|
  current_map = Traject::TranslationMap.new('umich/current_cop')
  obs_map = Traject::TranslationMap.new('umich/obsolete_cop')

  if r['008'] && (r['008'].value.size > 17)
    code = r['008'].value[15..17].gsub(/[^a-z]/, ' ')

    # Bail if we've got an explicit "undetermined"
    unless code == 'xx '
      possible_single_letter_country_code = code[2]
      container = if possible_single_letter_country_code.nil? || (possible_single_letter_country_code == ' ')
                    nil
                  else current_map['xx' << possible_single_letter_country_code]
                  end

      pop = current_map[code]
      pop ||= obs_map[code]

      # USSR? Check for the two-value version
      if possible_single_letter_country_code == 'r'
        container = 'Soviet Union'
        non_ussr_country = current_map[code[0..1] << ' ']
        acc << non_ussr_country if non_ussr_country
      end

      if pop
        if container
          acc << container
          acc << "#{container} -- #{pop}" unless pop == container
        else acc << pop
        end
      end
    end

  end
end

# Deal with the dates

# First, find the date and put it into context.clipboard[:ht_date] for later use
each_record extract_date_into_context

# Now use that value
to_field 'publishDate', get_date

def ordinalize_incomplete_year(s)
  i = s.to_s
  case i
  when /d\A1\d\Z/
    "#{i}th"
  when /\A\d?1\Z/
    "#{i}st"
  when /\A\d?2\Z/
    "#{i}nd"
  when /\A\d?3\Z/
    "#{i}rd"
  else "#{i}th"
  end
end

to_field 'display_date' do |_rec, acc, context|
  next unless context.output_hash['publishDate']

  rd = context.clipboard[:ht][:rawdate]
  if context.output_hash['publishDate'].first == rd
    acc << rd
  else if rd =~ /(\d\d\d)u/
         acc << "in the #{Regexp.last_match(1)}0s"
       elsif rd =~ /(\d\d)u+/
         acc << 'in the ' + ordinalize_incomplete_year(Regexp.last_match(1).to_i + 1) + ' century'
       elsif rd == '1uuu'
         acc << 'between 1000 and 1999'
       elsif rd == '2uuu'
         acc << 'between 2000 and 2999'
       end
  end
end

to_field 'publishDateRange' do |rec, acc, context|
  if context.output_hash['publishDate']
    d = context.output_hash['publishDate'].first
    dr = HathiTrust::Traject::Macros::HTMacros.compute_date_range(d)
    acc << dr if dr
  else id = if context.output_hash['id']
              context.output_hash['id'].first
            else '<no id in record>'
            end
  logger.debug "No valid date for record #{id}: #{rec['008']}"
  end
end

################################
########### MISC ###############
################################

to_field 'publisher', extract_marc('260b:264|*1|:533c')
to_field 'edition', extract_marc('250a')

to_field 'language', marc_languages('008[35-37]:041a:041d:041e:041j')

to_field 'language008', extract_marc('008[35-37]', first: true) do |_r, acc|
  acc.reject! { |x| x !~ /\S/ } # ditch only spaces
  acc.uniq!
end
