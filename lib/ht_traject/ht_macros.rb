module HathiTrust
  module Traject # Just need to define it so eval order doesn't matter
  end
end

module HathiTrust::Traject::Macros
    
  # Get a namespaced place to put all the ht stuff
  def self.setup
    lambda do |record, context| 
      context.clipboard[:ht] = {}
    end
  end
    
  def macr4j_as_xml
    lambda do |r, acc, context|
      xmlos = java.io.ByteArrayOutputStream.new
      writer = org.marc4j.MarcXmlWriter.new(xmlos)
      writer.setUnicodeNormalization(true)
      writer.write(context.clipboard[:ht][:marc4j]) 
      writer.writeEndDocument();
      acc << xmlos.toString
    end
  end
      
  
  # Stick some dates into the context object for later use
  def extract_date_into_context
    
    lambda do |r, context|
      if date = HTMacros.get_date(r)
        context.clipboard[:ht][:date] = date
      end
    end
  end
  
  
  
  
  class HTMacros
    
    # Get a date from a record, as best you can
    def self.get_date(r)
      bad_date_types = {
        'n' => true,
        # 'u' => true,
        'b' => true
      }
    
      only_four_digits = /\A\d{4}\Z/
      contains_four_digits = /(\d{4})/
      
      if r['008'] and r['008'].value.size > 10
        ohoh8 = r['008'].value
        date1 = ohoh8[7..10].downcase
        datetype = ohoh8[6]
        if bad_date_types.has_key?(datetype)
          date1 = ''
        else
          date1.gsub!('u', '0')
          date1.gsub!('|', ' ')
          date1 = '' if date1 == '0000'
        end
        
        if m = only_four_digits.match(date1)
          return date1
        end
      end
      
      # OK. If the 008 had a good date, we've already returned
      # it. Fall back on the 260c
      if r['260'] && r['260']['c']
        if m = contains_four_digits.match(r['260']['c'])
          return m[1]
        end
      end
      return nil
    end
    
    # Get a date range for easier faceting. 1800+ goes to the decade,
    # before that goes to the century, pre-1500 gets the string
    # "Pre-1500"
    #
    # Returns 'nil' for dates after 2100, presuming they're just wrong
    def self.compute_date_range(date)
      return nil unless date
      if date < "1500"
        return "Pre-1500"
      end

      case date.to_i
      when 1500..1800 then
        century = date[0..1]
        return century + '00-' + century + '99'
      when 1801..2100 then
        decade = date[0..2]
        return decade + "0-" + decade + "9";
      end
      return nil # default
    end
    
    
    
  end
  
end
