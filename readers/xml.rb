$:.unshift  "#{File.dirname(__FILE__)}/../lib"
require 'traject'
require 'marc/marc4j'
require 'traject/marc4j_reader'
require 'gzip_xml_reader'


settings do
  provide "reader_class_name", "Traject::GZipXMLReader"
  provide "marc_source.type", "xml"
end
