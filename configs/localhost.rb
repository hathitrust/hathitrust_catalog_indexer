require 'traject'
require 'socket'


settings do
  if Socket.gethostname =~ /waffle/
    provide "solr.url", "http://localhost:8983/solr/collection1"
  else
    provide "solr.url", "http://solr-sdr-catalog:9033/catalog"
  end
  provide "solrj_writer.parser_class_name", "BinaryResponseParser"
  provide "solrj_writer.commit_on_close", "true"
  provide "solrj_writer.thread_pool", 1
  provide "solrj_writer.batch_size", 50
  provide "writer_class_name", "Traject::SolrJWriter"
  provide 'processing_thread_pool', 2
  store "log.batch_size", 1_000
  
end