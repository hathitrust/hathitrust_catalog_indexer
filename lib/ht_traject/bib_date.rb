# frozen_string_literal: true

class HathiTrust::BibDate

  VALID_DATE_CHARS = /[\du]/

  class << self
    
    def get_bib_date(r)
      ohoh8 = r['008'].value
      datetype = ohoh8[6]

      case datetype
      when 'm',  # multiple dates
           'r',  # reprint; original date in date2, reprint in date1
           's'   # date2 has "probable date"
        date2(ohoh8) or date1(ohoh8) or '0000'
      else
        date1(ohoh8) or '0000'
      end
    end
    

    def date1(ohoh8)
      return nil unless ohoh8.size > 10

      dt = ohoh8[7..10]
      validated_datechars(dt)
    end

    def date2(ohoh8)
      return nil unless ohoh8.size > 14

      dt = ohoh8[11..14]
      validated_datechars(dt)
    end    

    def validated_datechars(dt)
      if VALID_DATE_CHARS.match(dt)    
        dt.gsub('u', '9')
      else
        nil
      end
    end

  end

end
