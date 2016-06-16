require 'traject'
require 'traject/solr_json_writer'

settings do
  provide "solr.url", "http://localhost:8027/solr/biblio"
  provide "solr_writer.commit_on_close", "true"
  provide "solr_writer.thread_pool", 2
  provide "solr_writer.batch_size", 60
  provide "writer_class_name", "Traject::SolrJsonWriter"
end
