# frozen_string_literal: true

require_relative "lc_subject"

module HathiTrust::Subject
  # There are a wide variety of non-LC subject types (e.g., MESH). For the
  # moment, just treat them all the same as LC Hierarchical, with delimiters
  # between every subfield value
  class NonLCSubject < HathiTrust::Subject::LCSubjectHierarchical

  end
end