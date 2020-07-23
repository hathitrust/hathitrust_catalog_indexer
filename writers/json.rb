require 'traject'
require 'traject/json_writer'

settings do
  store 'writer_class_name', 'Traject::JsonWriter'
  store 'output_file', 'debug.json'
  provide 'processing_thread_pool', 5
end
