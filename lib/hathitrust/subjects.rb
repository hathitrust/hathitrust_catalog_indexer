## frozen_string_literal: true

module Traject::Macros::HathiTrust
  module Subject

    LOWER_LETTER_PAT = /\p{Lower}/
    STRIP_PUNCT_PAT = /\A\p{Punct}*(.*?)\p{Punct}*\Z/

    def self.normalize_subject(str)
      STRIP_PUNCT_PAT.match(str)[1].gsub("/\s+/", ' ')
    end

    def self.eight_eighties_for(r, f)
      vid = f['6']
      if vid
        r.fields('880').select { |eef| eef['6']&.start_with? "#{f.tag}-#{vid.split("-").last}" }
      else
        []
      end
    end

    def self.subject_string(field)
      self.normalize_subject(field.subfields.select { |sf| LOWER_LETTER_PAT.match(sf.code) }.map(&:value).join("--"))
    end

    def self.subjects_by_ind2(r, ind2_pat)
      fields = r.fields.select { |f| f.tag[0] == '6' and ind2_pat.match(f.indicator2) }
      fields + fields.flat_map { |f| self.eight_eighties_for(r, f) }
    end
  end

  module SubjectMacros

    def lcsh_subjects
      ->(r, acc) do
        acc.replace Subject.subjects_by_ind2(r, /0/).map { |f| Subject.subject_string(f) }
      end
    end

    def non_lcsh_subjects
      ->(r, acc) do
        acc.replace Subject.subjects_by_ind2(r, /[^0]/).map { |f| Subject.subject_string(f) }
      end
    end
  end
end

