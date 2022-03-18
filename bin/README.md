# Scripts for indexing HT files

When we talk about "indexing" we generally mean:
  * run the delete file for today
  * index the marc file for today

The files here are almost all concerned with locating stuff to index and 
figuring out the date. The scripts in this directory thus set a bunch of 
environment variables that are used by the other scripts. 

Many of the important scripts give a `usage` when called with no arguments,
but some (like `fullindex`) just run, which is...dangerous.

At least some of this code is dead, and much of it is janky.

TODO: Replace `bin/` directory with a ruby script that take care of the 
date arithmetic, determines filenames from configuration/environment, etc. 

## Delete/indexing files

* [`tindex`](tindex) is the base program, where the indexing is actually done. It 
  sets the base directory, updates the translation maps, 
* [`delete_ids`](delete_ids) is the other half of what we need to do, delete from the 
  solr index records with the ids in the provided file.
* [`env/`](env/) is, I think, not used at all anymore. Need to confirm and delete.
* [`index_file`](index_file) has hardcoded values for the location of these scripts and 
  the files to process and errors out of if it can't find the marc file.
* [`index_date`](index_date) also hard codes file locations (???), figures out the dates,
  and calls `index_file`.
* Similarly, `catchup_today` and `catchup_since` call down the chain to 
  eventually call `index_date` with more date arithmetic along the way.
* [`fullindex`](fullindex) deletes the entire solr index, finds and indexes the more 
  recent full file, and then runs all the deletes/indexes from all the 
  days since then. It has a five-second delay when running so you can 
  panic and hit Ctrl-C. 

## Support files

* [`utils.sh`](utils.sh) has code to find the correct marc/delete files for a given
  date, the locations of which are semi-hard-coded throughout these scripts.
* [`get_namespaces`](get_namespaces) should be dead code
* [`get_collection_map.rb`](get_collection_map.rb) does what it says -- get the mapping of 
  collection codes to institution names from the database nd stuffs it 
  into `lib/translation_maps/ht`
* [`fetch_new_hlb`](fetch_new_hlb) is actually a script I ship with the HLB gem. Jeremy was 
  using High Level Browse data for...something? And Tom, too? But I don't 
  see why we bother at this point, as it's not exposed anywhere that I'm 
  aware of. We should check with the website to be sure.
* [`delete_all`](delete_all) is a utility to clear the solr index.
* [`update_tmaps_ht`](update_tmaps_ht) updates the translation maps, the only one of which 
  right now is collection codes. 
* [`set_java_home.sh`](set_java_home.sh) was because the java situation was a freakin' mess. 
  Probably unnecessary now, and certainly unnecessary once we have actual 
  installed jruby.
