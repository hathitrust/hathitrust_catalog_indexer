{
   :maptype=>:multi,
   :mapname=>"availability_map_ht_intl",
   :map => [
      [/^ic$/, "Search only"],
      [/^umall$/, "Full text"],
      [/^orph$/, "Search only"],
      [/world$/, "Full text"],       # matches world, ic-world, und-world,
      [/^nobody$/, "Search only"],
      [/^und$/, "Search only"],
      [/^opb?$/, "Full text"],

      [/^cc.*/, "Full text"],

      [/^pd$/, "Full text"],
      [/^pdus$/, "Search only"],


   ]
}