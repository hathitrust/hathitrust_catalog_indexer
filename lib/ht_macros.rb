module Traject::Macros
  module HathiTrust
    
    def please(&blk)
      badarg = true unless block_given?
      raise ArgumentError.new("No block given") if badarg
      
      lam = blk.call
      badarg =  true unless lam.is_a?(Proc)
      raise ArgumentError.new("perform takes a zero-arity block that returns a lambda") if badarg
      return lam
    end
    
    def extract_with_and_without_filing_characters(spec, opts={})
      only_first              = opts.delete(:first)
      trim_punctuation        = opts.delete(:trim_punctuation)
      default_value           = opts.delete(:default)
      
      extractor = Traject::MarcExtractor.cached(spec, opts)
      lambda do |record, accumulator, context|
        accumulator.concat HTMacros.get_with_and_without_filing(extractor, record)
        if only_first
          Marc21.first! accumulator
        end

        if trim_punctuation
          accumulator.collect! {|s| Marc21.trim_punctuation(s)}
        end

        if default_value && accumulator.empty?
          accumulator << default_value
        end
        
      end
      
    end
    
    
    # Stick some dates into the context object for later use
    def extract_date_into_context
      bad_date_types = {
        'n' => true,
        'u' => true,
        'b' => true
      }
      
      only_four_digits = /\A\d{4}\Z/
      contains_four_digits = /(\d{4})/
      
      lambda do |r, context|
        if r['008']
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
            context.clipboard[:ht_date] = date1
          end
        end
        
        # Go on and check the 260c if necessary
        if !context.clipboard[:ht_date] && r['260'] && r['260']['c']
          if m = contains_four_digits.match(r['260']['c'])
            context.clipboard[:ht_date] = m[1]
          end
        end
        
        # If we've got no date at all, log it
        
        unless context.clipboard[:ht_date]
          logger.debug "No valid date: #{r['001'].value}"
          return
        end
      end
      
    end
    
    
    
    
    class HTMacros
      def self.get_with_and_without_filing(extractor, record)
        rv = []
        extractor.collect_matching_lines(record) do |field, spec, ext| 
          str = ext.collect_subfields(field, spec).first
          next unless str
          non_filing = field.indicator2.to_i
          rv << str
          rv << str.slice(non_filing, str.length)
        end
        rv.uniq.compact
      end
      
      
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
end
