require 'traject'
require 'traject/debug_writer'
require 'traject/null_writer'
require 'thread'

require 'traject/umich_format'
extend Traject::UMichFormat::Macros



settings do
  provide "writer_class_name", "Traject::NullWriter"
  provide "output_file", "debug.out"
  provide 'processing_thread_pool', 3
  provide "log.batch_size", 10_000
  
end

to_field 'id', extract_marc('001', :first=>true)

difffile = $stderr
write_mutex  = Mutex.new

each_record do |rec, context|
  ex = Traject::MarcExtractor.cached('970a')
  begin
    orig = ex.extract(rec)
  
    orig_all = orig.dup.sort
  
    context.output_hash['O_All'] = orig_all
  
    context.output_hash['O_Format'] = [orig.shift]
    context.output_hash['O_Type'] = orig
  
    fd = Traject::UMichFormat.new(rec)
    new_all =  fd.format_and_types
    context.output_hash['N_All'] = new_all
    context.output_hash['N_Format'] = [fd.bib_format]
    context.output_hash['N_Type'] = fd.types.dup
  
  
    logger.warn "No original format for #{context.output_hash['id'].first}" unless context.output_hash['O_All'].size > 0
    logger.warn "No new      format for #{context.output_hash['id'].first}" unless context.output_hash['N_All'].size > 0
  
    unless orig_all == new_all
      diff = ((orig_all + new_all) - (orig_all & new_all))
      if diff.size > 0 and diff != ['CE'] and diff != ['PP']
        serialized = [context.output_hash['id'].first,  
                       orig_all.join(","), 
                       new_all.join(","),
                       diff.join(',')].join("\t")
         write_mutex.synchronize do
           difffile.puts(serialized)
         end
                     
       end
    end
  rescue Exception => e
    logger.error "Probelm with record #{context.output_hash['id'].first}: #{e}"
  end
  
end
  
