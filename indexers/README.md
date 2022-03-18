# Indexing rules

These files contain indexing rules for adding fields to the eventual solr 
document. In many cases, the heavy lifting is actually done by code in 
[`lib`](../lib).

There are files here that are no longer used and should probably be 
deleted. In any case, the list of files actually used (and the order in 
which they're loaded) can be derived from the bottom of [`tindex`](..
/bin/tindex). 

Once again, the structure here reflects the previous use of this as a 
common code base between HT and UMich.

Generally speaking:
* [`common.rb`](common.rb) loads everything up and contains definitions for 
  fields that only rely on "normal" bibliographic data. Because of all the 
  `requires` and such, it needs to be loaded first.
* [`common_ht.rb`](common_ht.rb) begins by just calling (via `each_record`)
  the hairy [`HathiTrust::Traject::ItemSet`](../lib/ht_traject/ht_item.rb) 
  code and sticking the result on the `context.clipboard`. From there it 
  derives item-level things like  access rights, change dates, etc. and 
  then turns them into record-level data.
* [`ht.rb`](ht.rb) continues to leverage the item stuff on the clipboard 
  and does database calls to get print holdings, does a bunch of 
  callnumber stuff for reasons I don't know (website?), and add the 
  `ht_json` structure for use by various other programs. 

Most of the code is fairly self-explanatory once you understand how 
`extract_marc` works. The huge exception, of course, is anything having to 
do with item-level stuff, all of which is magically placed on the 
clipboard as explained above.

TODO: Move `require/extend` code out of `common.rb` and into a file that 
can be used without loading everything else in that file, making it easier 
to run subsets of rules.

TODO: Decide if there's anything useful in the unused files in the 
`indexers/` directory and ditch whatever we don't want.

