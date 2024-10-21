require 'ht_traject/ht_constants'
require 'match_map'

mm = MatchMap.new

# Note: orph, orphcand, and umall are unattested in rights_current as of Oct 2024

# Within the FT vs SO groups, sort by numeric rights attribute
mm[/^pd(?:us)?$/] = HathiTrust::Constants::FT  # [1 pd, 9 pdus] (uses noncapturing parens)
mm[/.+world$/] = HathiTrust::Constants::FT     # [7 ic-world, 18 und-world]
mm[/^cc.*/] = HathiTrust::Constants::FT        # [10-15, 17, 20-25]


mm[/^ic(?:us)?$/] = HathiTrust::Constants::SO  # [2 ic, 19 icus] (uses noncapturing parens)
mm["op"] = HathiTrust::Constants::SO           # [3 op]
mm[/^orph/] = HathiTrust::Constants::SO        # [4 orph, 16 orphcand]
mm["und"] = HathiTrust::Constants::SO          # [5 und]
mm["umall"] = HathiTrust::Constants::SO        # [6 umall]
mm["nobody"] = HathiTrust::Constants::SO       # [8 nobody]
mm["pd-pvt"] = HathiTrust::Constants::SO       # [26 pd-pvt]
mm["supp"] = HathiTrust::Constants::SO         # [27 supp]

mm
