# Support code for HT indexing

This directory has become a ridiculously complex catch-all for code that 
seems too complex to inline into the `to_field` calls. While some things 
are marked HT and some UMich, live- and dead-code are sprinkled throughout.

There's no longer any reason for every single file to start with `ht_`. 

## Traject Macros -- an overview

A macro is just a method that returns a lambda that takes three arguments 
(record, accumulator, and context). The general use is to load those 
macros into the top namespace so they can be easily used, resulting in the 
pattern:

```ruby
require 'ht_traject/basic_macros'
extend HathiTrust::BasicMacros
```

If you don't want to do the `extend`, you can always call the macro with 
the full namespaced method name. 

## Guide to these files

### Dead code?

I'm pretty sure `umich_traject` is all stuff that we could ditch.

TODO: Figure out if we can ditch `lib/umich_traject`

### Monkey-patches

`ruby-marc` has a couple substantive speedups that can be gained if you 
know your record is frozen and that the MARC-XML output is going to be 
really simple. We can take advantage of both of these things.

* [`marc_record_speed_monkeypatch.rb`](marc_record_speed_monkeypatch.rb) 
  takes advantage of knowing how `ruby-marc` works and how `traject` calls 
  it to build a faster field lookup mechanism. The benchmarking code is 
  lost to the ravages of time, but it resulted in a substantial speedup of 
  running our code (low double-digit percentages, if I remember right).
* [`fast_xmlwriter.rb`](fast_xmlwriter.rb) is used to quickly (and not-so-safely in theory, 
  but not in practice) make a single MARC-XML file from a single MARC 
  record for inclusion in the solr stored fields (because it's used by LSS 
  indexing). The default record-to-marc-xml code uses ruby's REXML and is 
  unbearably slow -- the to-xml used to completely dominate any profiling. 

### Getting external data

Note: basic database connection code is 
in [`ht_traject/ht_dbh.rb`](ht_traject/ht_dbh.rb). Additionally, the non-git file `ht_secure_data.rb` 
is used for name/password/server/database info.

* Print holdings are gathered via a `Sequel` call to the database and 
  retrieved in batches (note the `SQL_NO_CACHE` directive needed to make 
  mysql not eat itself). When running under `NO_DB`, the mock print 
  holdings code simply returns ['UM'].
* The OCLC resolution table is consulted via
  [`oclc_resolution.rb`](ht_trject/oclc_resolution.rb). It does a simple 
  call against the table looking for the given ocn in both the "old" and 
  "canonical" columns. 
* [`redirects.rb`](ht_traject/redirects.rb) maps old record IDs to new 
  ones (where possible) and goes a different route. It actually just 
  loads the whole mapping (from 
  `/htapps/babel/hathifiles/catalog_redirects/redirects/`) into memory and consults it. If that file 
  ever gets too big we can think about moving it to a database table (or 
  even just an sqlite table on disk if we want).

### Macros

[`ht_traject/basic_macros.rb`](ht_traject/basic_macros.rb) has mostly 
generic post-processing macros not provided by the traject core (e.g., 
`compress_spaces`). 

The exception is the naconormalization macro, and its 
not-running-on-JRuby mock `FakeoNormalizer`. Naconormalization is a set of 
rules from the LoC that supposedly provide better sorting for 
transliterated text, and runs as a gem wrapped around OCLC java code. 

[`ht_traject/ht_macros.rb`](ht_traject/ht_macros.rb) is a bit of a 
mishmash. Some of the macros actually work on data assumed to already be 
in the clipboard. Much of it has to do with date computation. And the 
generic macro `extract_marc_unless` (allowing cleaner-looking conditional 
extraction) is also here. See also: 
the code in [`ht_traject/bib_date.rb`](ht_traject/bib_date.rb).

TODO: normalize/refactor all the macros

### ht_item.rb

This semi-nightmare builds up a structure that describes and transforms 
item-level data, aggregates item-level data into something that makes 
sense at the bib level, and tries to compute sort keys for enumchron. 

TODO: Document/refactor ht_item.rb







