# Turn a MARC record with 880 fields into one without
# (e.g., turn the 880 fields into their normal counterparts).
#
# Note that you'll end up with, say, more than one 245. That's what I want, but
# might not be what you want.

module MARC2Solr
  module Custom
    module MassageRecord

      # Use side effects to munge the MARC21 record in r into
      # one without 880s and then return the id.
      #
      # This is weird because the indexing code in marc2solr has
      # no provision for a side-effect only action; hence, returning
      # the id

      @tagpattern = /^(\d{3})-/ # we just want the first three items

      def self.massage_record_and_return_id(doc, r)
        ee = r.find_by_tag('880').each do |df|
          sf = df.subfields[0]
          next unless sf.code == '6'

          m = @tagpattern.match(sf.value)
          next unless m


          df.tag = m[1]
          df.remove_subfield(sf)
        end


        # Gotta rehash it
        r.rehash

        # OK, that's the end of the side effects. Now
        # just return the id in 001

        return r['001'].value

      end

    end
  end
end

__END__

MARC2Solr::Custom::DE880.de880_and_return_id(nil, r)

reader = MARC4J4R::Reader.new('ht_880test.seq', :alephsequential)
r = reader.next
r = reader.next
puts r
de880_and_return_id(nil, r)
puts r

