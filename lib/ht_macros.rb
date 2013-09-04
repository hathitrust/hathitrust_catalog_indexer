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
      
      extractor = Traject::MarcExtractor.new(spec, opts)
      lambda do |record, accumulator|
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
    
    class HTMacros
      def self.get_with_and_without_filing(extractor, record)
        rv = []
        extractor.collect_matching_lines(record) do |field, spec, ext| 
          str = ext.collect_subfields(field, spec).first
          non_filing = field.indicator2.to_i
          rv << str
          rv << str.slice(non_filing, str.length)
        end
        rv.uniq
      end
    end
    
  end
end
