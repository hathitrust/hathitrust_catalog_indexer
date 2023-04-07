# frozen_string_literal: true

require "date"

class Date
  def self.last_day_of_last_month(reference_date = today)
    reference_date - reference_date.mday
  end

  # Return argument intact if Date object, or new Date object if String
  # or coercible to String.
  def self.with(obj)
    return obj if obj.is_a? Date
    begin
      Date.parse(obj.to_s)
    rescue => e
      raise CICTL::CICTLError.new "unable to parse \"#{obj}\" (#{e})"
    end
  end
end
