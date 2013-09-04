require 'rubygems'
require 'jlogger'
require 'library_stdnums'

module MARC2Solr
  module Custom
    LOG = JLogger::RootLogger.new
    
    # Custom routines are defined as module methods that take two arguments: a MARC4J4R record,
    # and an (optional) array of other arguments passed in. 
    #
    # They don't need to live in the MARC2Solr::Custom namespace, but it's not a bad idea to use, e.g.,
    # MARC2Solr::Custom::UMich, or maybe MARC2Solr::Custom::DateStuff
    #
    # You can return multiple values in an array
    
    # The simplest possible example; just call a method on the underlying MARC4J4R record
    # Note that even though we don't use the arguments, the method signature has to 
    # support it
    #
    # @param [hashlike] doc The document object being added to; allows you to leverage already-done work
    # @param [MARC4J4R::Record] r A MARC4J4R record
    # @param [#[]] doc A hashlike (responds to #[]) that holds the computed values for fields "so far"
    # @return [String] The XML representation of the record

    def self.asXML doc, r  #Remember, module fucntion! Define with "def self.methodName"
      return r.to_xml
    end
    
    # Another for marc binary
    def self.asMARC doc, r
      return r.to_marc
    end
    
    
    # And another for marc-in-json
    
    def self.as_marc_in_json doc, r
      return r.to_marc_in_json
    end
    
    # Here we get all the text from fields between (inclusive) the two tag strings in args;
    # 
    # @param [hashlike] doc The document object being added to; allows you to leverage already-done work
    # @param [MARC4J4R::Record] r A MARC4J4R record
    # @param [Array<String>] args An array of two strings, the lowest tag you want to include, and
    # the highest
    # @return [String] A single single string with all the text from included fields
    def self.getAllSearchableFields(doc, r, lower, upper)
      data = []
      r.each do |field|
        next unless field.tag <= upper and field.tag >= lower
        data << field.value
      end
      return data.join(' ')
    end
    
    # How about one to sort out, say, the 035s? We'll make a generic routine
    # that looks for specified values in specified subfields of variable
    # fields, and then make sure they match before returning them.
    #
    # See the use of this in the simple_sample/simple_index.rb file for field 'oclc'
    #
    # @param [hashlike] doc The document object being added to; allows you to leverage already-done work
    # @param [MARC4J4R::Record] r A MARC4J4R record
    # @param [String] tag A tag string (e.g., '035')
    # @param [String, Array<String>] codes A subfield code ('a') or array of them (['a', 'c'])
    # @param [Regexp] pattern A pattern that must match for the value to be included
    # @param [Fixnum] matchindex The number of the substring captured by parens in the pattern to return
    # The default is zero, which means "the whole string"
    # @return [Array<String>] a (possibly empty) array of found values
    def self.valsByPattern(doc, r, tag, codes, pattern, matchindex=0)
      data = []
      r.find_by_tag(tag).each do |f|
        f.sub_values(codes).each do |v|
          if m = pattern.match(v)
            data << m[matchindex]
          end
        end
      end
      data.uniq!
      return data
    end
    
    # Extract an ISBN from the given subfields of the 020 and provide
    # both 10-character and 13-digit versions for each. If they appear
    # to not be ISBNs, just return the original value
    
    def self.getISBNS doc, r, codes=['a', 'z']
      rv = []
      r.find_by_tag('020').each do |f|
        f.sub_values(codes).each do |v|
          std = StdNum::ISBN.allNormalizedValues(v)
          if std.size > 0
            rv.concat std
          else
            rv << v
          end
        end
      end
      return rv
    end
    
    # An example of a DateOfPublication implementation
    # @param [hashlike] doc The document object being added to; allows you to leverage already-done work
    # @param [MARC4J4R::Record] r A MARC4J4R record
    # @return [String] the found date, or nil if not found.
    
    def self.getDate doc, r
      begin
        ohoh8 = r['008'].value
        date1 = ohoh8[7..10].downcase
        datetype = ohoh8[6..6]
        if ['n','u','b'].include? datetype
          date1 = ""
        else 
          date1 = date1.gsub('u', '0').gsub('|', ' ')
          date1 = '' if date1 == '0000'
        end

        if m = /^\d\d\d\d$/.match(date1)
          return m[0]
        end
      rescue
       # do nothing ... go on to the 260c
      end


      # No good? Fall back on the 260c
      begin
        d =  r['260']['c']
        if m = /\d\d\d\d/.match(d)
          return m[0]
        end
      rescue
        LOG.debug "Record #{r['001']} has no valid date"
        return nil
      end
    end    
    
    # A simple function to pull the non-indexing characters off the front of a field
    # based on the second indicator
    def self.fieldWithoutIndexingChars doc, r, tag
      vals = []
      r.find_by_tag(tag).each do |df|
        ind2 = df.ind2.to_i
        if ind2 > 0
          vals << df.value[ind2..-1]
        end
      end
      return vals
    end
    
    
    # A helper function -- take in a year, and return a date category
    def self.getDateRange(date, r)
      if date < "1500"
        return "Pre-1500"
      end

      case date.to_i
      when 1500..1800 then 
        century = date[0..1]
        return century + '00' + century + '99'
      when 1801..2100 then
        decade = date[0..2]
        return decade + "0-" + decade + "9";
      else
  #      puts "getDateRange: #{r['001'].value} invalid date #{date}"
      end
    end
    
    
    # Get the date range, based on the previously-computed pubdate
      def self.pubDateRange(doc, r, wherePubdateIsStored)
       previouslyComputedPubdate = doc[wherePubdateIsStored][0]
       return [self.getDateRange(previouslyComputedPubdate)]
      end
    
    
    # We can do the same thing as a multi-return function -- compute the pubdate and
    # the pubdaterange in one fell swoop. 
    #
    # In this case, we *could* just use the above self.pubDateRange. However, there
    # are times when you several fields are based on intermediate values that you
    # don't want to actually store in the solr document itself (e.g., a set of call number
    # that you want to normalize or translate in a few different ways, without actually wanting
    # to store the raw callnumbers in their own field). You may also need access to more metadata
    # as you're constructing the data (e.g., you may want to store titles and titles-without-non-filing-
    # character in different fields, but you can't compute one from the other wihout access to the
    # associated indicator-2 value). 
    #
    # So, in this case, we'll get the pubDate and the pubDateRange all at once, just as an example,
    # and put in the custom spec as:
    #
    # {
    #   :solrField => ['pubDate', 'pubDateRange'],
    #   :module => MARC2Solr::Custom,
    #   :functionSymbol => :pubDateAndRange
    # }
    
    
    def self.pubDateAndRange(doc, r)
      date = self.getDate(doc, r)
      return [nil, nil] unless date
      range = self.getDateRange(date, r)
      return [date, range]
    end
    
    
  end # close the inner module Custom
end # close the module MARC2Solr
    