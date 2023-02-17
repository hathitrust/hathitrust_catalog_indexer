# frozen_string_literal: true

module HathiTrust
  module Subject
  end
end

require_relative "subject/lc_subject"
require_relative "subject/non_lc_subject"

module HathiTrust::Subject

  # We define subjects as being in any of these fields:
  SUBJECT_FIELDS = %q(600 610 611 630 648 650 651 653 654 655 656 657 658 662 690)
  
  def self.subject_field?(field)
    SUBJECT_FIELDS.include?(field.tag)
  end

  # Delegate LC determination to the class itself.
  def self.lc_subject_field?(field)
    LCSubject.lc_subject_field?(field)
  end

  # Determin the 880 (linking fields) for the given field. Should probably be pulled
  # out into a more generically-available macro
  # @param [MARC::Record] record The record
  # @param [MARC::DataField] field The field you want to try to match
  # @return [Array<MARC::DataField>] A (possibly empty) array of linked fields
  def self.linked_fields_for(record, field)
    linking_id = field['6']
    if linking_id
      record.fields('880').select { |eef| eef['6']&.start_with? "#{field.tag}-#{linking_id.split("-").last}" }
    else
      []
    end
  end

  # Get all the subject fields including associated 880 linked fields
  # @param [MARC::Record] record The record
  # @return [Array<MARC::DataField>] A (possibly empty) array of subject fields and their
  # linked counterparts, if any
  def self.subject_fields(record)
    sfields = record.select { |field| subject_field?(field) }
    sfields + sfields.flat_map { |field| linked_fields_for(record, field) }.compact
  end

  # Get only the LC subject fields and any associated 880 linked fields
  # @param [MARC::Record] record The record
  # @return [Array<MARC::DataField>] A (possibly empty) array of LC subject fields and their
  # linked counterparts, if any
  def self.lc_subject_fields(record)
    sfields = record.select { |field| lc_subject_field?(field) }
    sfields + sfields.flat_map { |field| linked_fields_for(record, field) }.compact
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

