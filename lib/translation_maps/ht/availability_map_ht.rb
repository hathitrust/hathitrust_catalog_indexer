require 'ht_traject/ht_constants'
require 'match_map'

mm = MatchMap.new

mm[/^umall$/] = HathiTrust::Constants::FT
mm[/world$/] = HathiTrust::Constants::FT       # matches world, ic-world, und-world
mm[/^cc.*/] = HathiTrust::Constants::FT
mm[/^pd(?:us)?$/] = HathiTrust::Constants::FT  # pd or pdus

mm[/^ic$/] = HathiTrust::Constants::SO
mm[/^orph$/] = HathiTrust::Constants::SO
mm[/^nobody$/] = HathiTrust::Constants::SO
mm[/^und$/] = HathiTrust::Constants::SO
mm[/^pd-p/] = HathiTrust::Constants::SO        # pd-pvt or pd-private
mm[/^opb?$/] = HathiTrust::Constants::SO

mm
