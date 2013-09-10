SO = "Search only"
FT = "Full text"

mm = MatchMap.new
mm['ic'] = SO
mm['umall'] = FT
mm['orph'] = SO
mm['world'] = FT       # matches world, ic-world, und-world
mm['nobody'] = SO
mm['und'] = SO
mm[/^opb?$/] = FT
mm[/^cc.*/] = FT
mm['pd'] = FT
mm['pdus'] = SO

mm
