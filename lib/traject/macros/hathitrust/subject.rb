## frozen_string_literal: true

require "hathitrust/subject"

module Traject::Macros::HathiTrust

  # Code to extract subject fields (and their string representations) from the 600-699
  # fields of a MARC record.
  module Subject
    def lcsh_subjects
      ->(record, accumulator) do
        subject_fields = HathiTrust::Subject.lc_subject_fields(record)
        subjects = subject_fields.map{|f| HathiTrust::Subject.new(f)}
        accumulator.replace subjects.map { |s| s.subject_string }
      end
    end

    def non_lcsh_subjects
      ->(record, accumulator) do
        subject_fields = HathiTrust::Subject.subject_fields(record) - HathiTrust::Subject.lc_subject_fields(record)
        subjects = subject_fields.map{|f| HathiTrust::Subject.new(f)}
        accumulator.replace subjects.map { |s| s.subject_string }
      end
    end
  end
end
