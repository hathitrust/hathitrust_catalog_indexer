require_relative "../lib/ht_traject/ht_print_holdings"


HathiTrust::PrintHoldings::DB[:ht_namespaces].select(:namespace, :institution).map(&:values).each do |n,i|
  puts [n,i].join("\t")
end

