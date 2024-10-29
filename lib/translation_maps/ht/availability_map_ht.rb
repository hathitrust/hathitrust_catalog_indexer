require "ht_traject/ht_constants"
require "match_map"

mm = MatchMap.new

# Note: orph, orphcand, and umall are unattested in rights_current as of Oct 2024

# Full Text
mm["pd"] = HathiTrust::Constants::FT           # [1]
mm["ic-world"] = HathiTrust::Constants::FT     # [7]
mm["pdus"] = HathiTrust::Constants::FT         # [9]
mm[/^cc-/] = HathiTrust::Constants::FT         # [10-15, 17, 20-25]
mm["und-world"] = HathiTrust::Constants::FT    # [18]

# Search Only
mm["ic"] = HathiTrust::Constants::SO           # [2]
mm["op"] = HathiTrust::Constants::SO           # [3]
mm["orph"] = HathiTrust::Constants::SO         # [4]
mm["und"] = HathiTrust::Constants::SO          # [5]
mm["umall"] = HathiTrust::Constants::SO        # [6]
mm["nobody"] = HathiTrust::Constants::SO       # [8]
mm["orphcand"] = HathiTrust::Constants::SO     # [16]
mm["icus"] = HathiTrust::Constants::SO         # [19]
mm["pd-pvt"] = HathiTrust::Constants::SO       # [26]
mm["supp"] = HathiTrust::Constants::SO         # [27]

mm
