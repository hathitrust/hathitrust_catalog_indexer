# Copied from hathitrust_catalog_indexer/lib/ht_traject/ht_macros.rb

#FIXME: see also athiTrust::BibDate in lib/ht_traject and move that stuff here

module HathiTrust
  class RecordDate
    attr_reader :catalog_record

    # Some dates we're not going to bother with
    BAD_DATE_TYPES = {
      "n" => true,
      # "u" => true,
      "b" => true
    }.freeze

    # FIXME: self.contains_four_digits? class method?
    #Or self.extract_four_digits
    CONTAINS_FOUR_DIGITS = /(\d{4})/

    #TODO: this is moving from `ht_macros`
    # Get a date range for easier faceting. 1800+ goes to the decade,
    # before that goes to the century, pre-1500 gets the string
    # "Pre-1500"
    #
    # Returns 'nil' for dates after 2100, presuming they're just wrong
    # Takes a String or Integer
    def self.compute_date_range(date)
      return nil if date.nil?

      date = date.to_s
      return "Pre-1500" if date.to_i < 1500

      case date.to_i
      when 1500..1800
        century = date[0..1]
        return century + "00-" + century + "99"
      when 1801..2100
        decade = date[0..2]
        return decade + "0-" + decade + "9"
      end
      nil # default
    end

    # Given first two digits of a four-digit year, translate into ordinal string.
    def self.ordinalize_incomplete_year(year)
      case year.to_s
      when /\A\d?1\d\Z/
        "#{year}th"
      when /\A\d?1\Z/
        "#{year}st"
      when /\A\d?2\Z/
        "#{year}nd"
      when /\A\d?3\Z/
        "#{year}rd"
      else "#{year}th"
      end
    end

    def initialize(catalog_record:)
      @catalog_record = catalog_record
    end

    #TODO: moved from common.rb
    # Used verbatim as the Solr `display_date` field.
    #TODO: is it ever possible to get multiple values? If not, rename this `ddisplay_date` and
    # `[X]` the result in the Traject macro
    def display_dates
      return nil if raw_date.nil?

      dates = []
      if date == raw_date
        dates << raw_date
      elsif raw_date =~ /(\d\d\d)u/
        dates << "in the #{Regexp.last_match(1)}0s"
      elsif raw_date =~ /(\d\d)u+/
        dates << "in the " + self.class.ordinalize_incomplete_year(Regexp.last_match(1).to_i + 1) + " century"
      elsif raw_date == "1uuu"
        dates << "between 1000 and 1999"
      elsif raw_date == "2uuu"
        dates << "between 2000 and 2999"
      end
    end

    # Get a date from a record, as best you can
    # Try to get it from the 008; if not, the 260
    # Used for deriving the `display_date` Solr field (see `display_dates` method.
    def raw_date
      @raw_date ||= field_008_date || field_260_date
    end

    # The raw date with "u" bytes replaced with zeroes.
    # Used verbatim (in an Array) in the Solr `publishDate` field.
    def date
      @date ||= raw_date&.tr("u", "0")
    end

    def field_008_date
      return nil unless r["008"] && (r["008"].value.size > 10)

      value = r["008"].value
      return nil if BAD_DATE_TYPES.key?(value[6])

      date = value[7..10].downcase
      return nil if (date == "0000") || date.match?(/\|/)
      return nil unless date.match?(/\A\d[\du]{3}/)

      date
    end

    # Returns the first matching 4-digit date if found.
    def field_260_date
      return nil unless r["260"] && r["260"]["c"]

      m = CONTAINS_FOUR_DIGITS.match(r["260"]["c"])
      m && m[1]
    end

    private

    #FIXME this is just a convenience -- rename to marc_record?
    def r
      catalog_record.marc_record
    end
  end
end
