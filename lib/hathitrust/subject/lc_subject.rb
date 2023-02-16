# frozen_string_literal: true

require_relative "normalize"

module HathiTrust::Subject

  class LCSubject
    include HathiTrust::Subject::Normalize

    # @param [MARC::DataField] field
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

    # @param [MARC::DataField] field
    def self.lc_subject_field?(field)
      ('600'..'699').cover?(field.tag) and
        field.indicator2 == '0'
    end

    def initialize(field)
      @field = field
    end

    def alphabetic_subfields
      @field.select { |sf| ('a'..'z').cover?(sf.code) }
    end

    def delimiter
      "--"
    end

    # Most subject fields are constructed by joining together the alphabetic subfields
    # with either a '--' (before a $v, $x, $y, or $z) or a space (before everything else).
    # @return [String] An appropriately-delimited string
    def subject_string
      str = alphabetic_subfields.map do |sf|
        case sf.code
          when 'v', 'x', 'y', 'z'
            "#{delimiter}#{sf.value}"
          else
            " #{sf.value}"
        end
      end.join('').gsub(/\A\s*#{delimiter}/, '')
      normalize(str)
    end

  end

  class LCSubject658 < LCSubject

    def subject_string
      str = alphabetic_subfields.map do |sf|
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

    def subject_string
      normalize(alphabetic_subfields.map(&:value).join("--"))
    end
  end

end