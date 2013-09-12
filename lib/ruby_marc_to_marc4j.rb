require 'marc'
require 'traject'

module HathiTrust
class MARC2MARC4J
  def initialize(settings)
    # Load up the libraries
    unless defined?(MarcPermissiveStreamReader)
      Traject::Util.require_marc4j_jars(settings)
    end

    @factory = org.marc4j.marc::MarcFactory.newInstance
    
    if settings['marc4j_reader.keep_marc4j'] &&
      ! (MARC::Record.instance_methods.include?(:original_marc4j) &&
         MARC::Record.instance_methods.include?(:"original_marc4j="))
      MARC::Record.class_eval('attr_accessor :original_marc4j')
    end
    
  end
  
  def convert_to_marc4j(r)
    j = @factory.newRecord(r.leader)
    r.each do |f|
      if f.is_a? MARC::ControlField
        new_field = @factory.newControlField(f.tag, f.value)
      else
        new_field = @factory.new_data_field(f.tag, f.indicator1.ord, f.indicator2.ord)
        f.each do |sf|
          new_field.add_subfield(@factory.new_subfield(sf.code.ord, sf.value))
        end
      end
      j.add_variable_field(new_field)
    end
    return j
  end
  
  def add_marc4j_to_record(r)
    r.original_marc4j = self.convert_to_marc4j(r)
  end
    
  end
end
    

