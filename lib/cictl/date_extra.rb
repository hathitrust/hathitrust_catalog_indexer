# frozen_string_literal: true

require "date"
require "pry"

class Date
  def self.last_day_of_last_month(reference_date = today)
    reference_date - reference_date.mday
  end

  # Return argument intact if Date object, or new Date object if String
  # or able to return a string.
  # FIXME: this can raise if the string cannot be parsed as a date,
  # make sure bogus inputs are intercepted or exceptions are handled.
  def self.with(obj)
    obj.is_a?(Date) ? obj : Date.parse(obj.to_s)
  end
end
