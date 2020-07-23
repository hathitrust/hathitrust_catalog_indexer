require 'yell'

log955 = Yell::Logger.new '955.txt', format: '%m'

to_field 'id', extract_marc('001', first: true)
to_field 'barcode', extract_marc('955b')
to_field 'echron', extract_marc('955v')

each_record do |_rec, context|
  oh = context.output_hash
  log955.warn [oh['id'], oh['barcode'], oh['echron']].join("\t")
end
