## frozen_string_literal: true

module Traject::Macros::HathiTrust
  module Subject

    LOWER_LETTER_PAT = /\p{Lower}/
    STRIP_PUNCT_PAT = /\A\p{Punct}*(.*?)\p{Punct}*\Z/

    # Strip leading/trailing punctuation
    # @param [String] string of a subject
    # @return [String] The normalized subject string
    def self.normalize_subject(str)
      STRIP_PUNCT_PAT.match(str)[1].gsub("/\s+/", ' ')
    end

    # Determin the 880 (linking fields) for the given field. Should probably be pulled
    # out into a more generically-available macro
    # @param [MARC::Record] r The record
    # @param [MARC::DataField] f The field you want to try to match
    # @param [Array<MARC::DataField>] A (possibly empty) array of linked fields
    def self.eight_eighties_for(r, f)
      vid = f['6']
      if vid
        r.fields('880').select { |eef| eef['6']&.start_with? "#{f.tag}-#{vid.split("-").last}" }
      else
        []
      end
    end

    # Get all the subfields of the given field and join them together with '--'
    # @param [MARC::DataField] field
    # return [String] a '--' delimited string of all  the lettered subfields
    def self.subject_string(field)
      self.normalize_subject(field.subfields.select { |sf| LOWER_LETTER_PAT.match(sf.code) }.map(&:value).join("--"))
    end

    # Select subjects from the 6xx fields based on the value of ind2
    def self.subjects_by_ind2(r, ind2_pat)
      fields = r.fields.select { |f| f.tag[0] == '6' and ind2_pat.match(f.indicator2) }
      fields + fields.flat_map { |f| self.eight_eighties_for(r, f) }
    end
  end

  module SubjectMacros

    # Find all the 6xx fields with ind2==0 and turn them into subject strings
    def lcsh_subjects
      ->(r, acc) do
        acc.replace Subject.subjects_by_ind2(r, /0/).map { |f| Subject.subject_string(f) }
      end
    end

    # Find all the 6xx fields with ind2!=0 and turn them into subject strings
    def non_lcsh_subjects
      ->(r, acc) do
        acc.replace Subject.subjects_by_ind2(r, /[^0]/).map { |f| Subject.subject_string(f) }
      end
    end
  end
end

