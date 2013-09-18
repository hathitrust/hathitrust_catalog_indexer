require 'marc'
require 'traject'
require 'json'
require 'zlib'

class Traject::NDJReader < Traject::MarcReader
  
  def initialize(input_stream, settings)
    super
    @settings = settings
    if settings['command_line.filename'] =~ /\.gz$/
      @input_stream = Zlib::GzipReader.new(@input_stream, :external_encoding => "UTF-8")
    end
  end
  
  def logger
    @logger ||= (settings[:logger] || Yell.new(STDERR, :level => "gt.fatal")) # null logger)
  end    

  def each
    unless block_given?
      return enum_for(:each)
    end
    
    @input_stream.each_with_index do |json, i|
      begin
        yield MARC::Record.new_from_hash(JSON.parse(json))
      rescue Exception => e
        self.logger.error("Problem with JSON record online #{i}: #{e.message}")
      end
    end
  end
  
end
        
     