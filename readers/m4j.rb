require 'traject'
require 'marc/marc4j'
require 'traject/marc4j_reader'

settings do
  store 'reader_class_name', 'Traject::Marc4JReader'
  store 'marc4j_reader.keep_marc4j', true
end
