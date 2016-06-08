require 'traject'
require 'traject/solr_json_writer'

settings do
  provide "solr.url", "http://localhost:8027/solr/biblio"
  provide "solrj_writer.commit_on_close", "true"
  provide "solrj_writer.thread_pool", 2
  provide "solrj_writer.batch_size", 100
  provide "writer_class_name", "Traject::SolrJsonWriter"
end
