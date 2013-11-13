require 'traject'
require 'traject/marc4j_reader'
require 'zlib'



class Traject::GZipXMLReader < Traject::Marc4JReader
  def create_marc_reader!
    case input_type
    when "binary"
      permissive = settings["marc4j_reader.permissive"].to_s == "true"

      # #to_inputstream turns our ruby IO into a Java InputStream
      # third arg means 'convert to UTF-8, yes'
      MarcPermissiveStreamReader.new(input_stream.to_inputstream, permissive, true, settings["marc4j_reader.source_encoding"])
    when "xml"
      if @settings['command_line.filename'] =~ /\.gz$/
        @input_stream =  Java::java.util.zip.GZIPInputStream.new(@input_stream.to_inputstream)
      else
        @input_stream = @input_stream.to_inputstream
      end
      
      MarcXmlReader.new(@input_stream)
    else
      raise IllegalArgument.new("Unrecgonized marc_source.type: #{input_type}")
    end
  end
end