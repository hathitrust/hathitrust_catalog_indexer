require 'traject'
require 'traject/debug_writer'
require 'marc/marc4j'
require 'traject/marc4j_reader'
require_relative '../lib/ht_format'


settings do
  store "reader_class_name", "Traject::Marc4JReader"
  store "marc4j_reader.keep_marc4j", true
  store "writer_class_name", "Traject::DebugWriter"
  store "output_file", "debug.out"
  store 'processing_thread_pool', 0
end

to_field 'id', extract_marc('001', :first=>true)

each_record do |rec, context|
  ex = Traject::MarcExtractor.new('970a')
  orig = ex.extract(rec)
  
  orig_all = orig.dup.sort
  
  context.output_hash['O_All'] = orig_all
  
  context.output_hash['O_Format'] = [orig.shift]
  context.output_hash['O_Type'] = orig
  
  fd = HathiTrust::Format_Detector.new(rec)
  new_all =  [fd.bib_format, fd.types].flatten.sort.dup
  context.output_hash['N_All'] = new_all
  context.output_hash['N_Format'] = [fd.bib_format]
  context.output_hash['N_Type'] = fd.types.dup
  
  
  logger.warn "No original format for #{context.output_hash['id'].first}" unless context.output_hash['O_All'].size > 0
  logger.warn "No new      format for #{context.output_hash['id'].first}" unless context.output_hash['N_All'].size > 0
  
  unless orig_all == new_all
    diff = ((orig_all + new_all) - (orig_all & new_all))
    if diff.size > 0 and diff != ['CE'] and diff != ['PP']
      logger.warn '%-9s %-16s | %-16s (%-10s)' % [context.output_hash['id'].first,  orig_all.join(","), new_all.join(","),
       diff.join(',')]
     end
  end
  
end
  
