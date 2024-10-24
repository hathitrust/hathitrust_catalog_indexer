require "ht_traject/ht_constants"

mm = MatchMap.new

# Note: orph, orphcand, and umall are unattested in rights_current as of Oct 2024

# Within the FT vs SO groups, sort by numeric rights attribute
mm["pd"] = HathiTrust::Constants::FT           # [1 pd]
mm[/.+world$/] = HathiTrust::Constants::FT     # [7 ic-world, 18 und-world]
mm[/^cc.*/] = HathiTrust::Constants::FT        # [10-15, 17, 20-25]
mm["icus"] = HathiTrust::Constants::FT         # [19 icus]

mm["ic"] = HathiTrust::Constants::SO           # [2 ic]
mm["op"] = HathiTrust::Constants::SO           # [3 op]
mm[/^orph/] = HathiTrust::Constants::SO        # [4 orph, 16 orphcand]
mm["und"] = HathiTrust::Constants::SO          # [5 und]
mm["umall"] = HathiTrust::Constants::SO        # [6 umall]
mm["nobody"] = HathiTrust::Constants::SO       # [8 nobody]
mm["pdus"] = HathiTrust::Constants::SO         # [9 pdus]
mm["pd-pvt"] = HathiTrust::Constants::SO       # [26 pd-pvt]
mm["supp"] = HathiTrust::Constants::SO         # [27 supp]

mm
