# frozen_string_literal: true

require_relative "normalize"

module HathiTrust::Subject

  class LCSubject
    include HathiTrust::Subject::Normalize

    # Create an LC Subject object from the passed field
    # @param [MARC::DataField] field _that has already been determined to be LC_
    # @return [LCSubject] An LC Subject or appropriate subclass
    def self.from_field(field)
      case field.tag
        when "658"
          LCSubject658.new(field)
        when "662"
          LCSubjectHierarchical(field)
        else
          new(field)
      end
    end

    # Define an LC subject field as any 6xx with ind2==0
    # @param [MARC::DataField] field
    # @return [Boolean]
    def self.lc_subject_field?(field)
      SUBJECT_FIELDS.include?(field.tag) and
        field.indicator2 == '0'
    end

    def initialize(field)
      @field = field
    end

    def subject_data_subfield_codes
      @field.select { |sf| ('a'..'z').cover?(sf.code) }
    end

    def delimiter
      "--"
    end

    # Only some fields get delimiters before them in a standard LC Subject field
    DELIMITED_FIELDS = %w(v x y z)

    # Most subject fields are constructed by joining together the alphabetic subfields
    # with either a '--' (before a $v, $x, $y, or $z) or a space (before everything else).
    # @return [String] An appropriately-delimited string
    def subject_string
      str = subject_data_subfield_codes.map do |sf|
        case sf.code
          when *DELIMITED_FIELDS
            "#{delimiter}#{sf.value}"
          else
            " #{sf.value}"
        end
      end.join('').gsub(/\A\s*#{delimiter}/, '')
      normalize(str)
    end

  end

  class LCSubject658 < LCSubject

    # Format taken from the MARC 658 documentation
    # @return [String] Subject string ready for output
    def subject_string
      str = subject_data_subfield_codes.map do |sf|
        case sf.code
          when 'b'
            ": #{sf.value}"
          when 'c'
            " [#{sf.value}]"
          when 'd'
            "#{DELIM}#{sf.value}"
          else
            " #{sf.value}"
        end.join('').gsub(/\A\s*#{delimiter}/, '')
        normalize(str)
      end
    end
  end

  # Purely hierarchical fields can just have all their parts
  # joined together with the delimiter
  class LCSubjectHierarchical < LCSubject

    # At least one subject field in LC, the 652, just gets delimiters everywhere
    # Format taken from the MARC 652 documentation
    # @return [String] Subject string ready for output
    def subject_string
      normalize(subject_data_subfield_codes.map(&:value).join(delimiter))
    end
  end

end