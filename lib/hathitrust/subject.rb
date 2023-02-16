# frozen_string_literal: true

module HathiTrust
  module Subject
  end
end

require_relative "subject/lc_subject"
require_relative "subject/non_lc_subject"

module HathiTrust::Subject
  def self.subject_field?(field)
    ('600'..'699').cover?(field.tag)
  end

  def self.lc_subject_field?(field)
    LCSubject.lc_subject_field?(field)
  end

  # Pass off a new subject to the appropriate class
  def self.new(field)
    if lc_subject_field?(field)
      LCSubject.from_field(field)
    else
      NonLCSubject.new(field)
    end
  end
end

