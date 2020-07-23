$:.unshift "#{File.dirname(__FILE__)}/../lib"
require 'traject'

settings do
  provide 'marc_source.type', 'xml'
end
