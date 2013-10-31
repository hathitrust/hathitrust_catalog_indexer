$:.unshift  "#{File.dirname(__FILE__)}/../lib"

require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

require 'ht_traject/ht_macros'
require 'ht_traject/ht_item'
extend HathiTrust::Traject::Macros

require 'traject/umich_format'
extend Traject::UMichFormat::Macros

require 'ht_traject/fast_xmlwriter'
 

settings do
  store "log.batch_progress", 10_000
end

logger.info RUBY_DESCRIPTION

################################
###### Setup ###################
################################

# Set up an area in the clipboard for use storing intermediate stuff
each_record HathiTrust::Traject::Macros.setup

