# Hathitrust Catalog Indexing and Solr Configuration


There are two quasi-independent parts to this repository:
* [solr/](solr/) contains all of the configuration for the catalog solr,
  which currently uses a non-managed schema (i.e., we hand-edit the
  `schema.xml` file)
* Everything else is concerned with the actual indexing code (based on
  [traject](https://github.com/traject/traject/))

In addition to this overview, more detailed explanations can be found in:
* [`bin/README.md`](bin/README.md)
* [`lib/README.md`](lib/README.md)
* [`indexers/README.md`](indexers/README.md)

## Getting Started with Docker

### Setup

```bash

docker-compose build
docker-compose up -d solr-sdr-catalog
docker-compose run --rm traject bundle install
docker-compose run --rm traject bundle exec fetch_new_hlb ./lib/translation_maps
```

### Index one file

Index a file of records without using the database or hardcoded filesystem paths:

```
# get some sample records somehow
docker-compose run traject bin/index_file examples/sample_records.json.gz
# ensure documents are committed
source bin/utils.sh; solr_url; commit
```

### Do a full index

Zephir records for the last monthly up to the current date should be in `examples`:

```bash

docker-compose run traject bin/fullindex
```

### Query Solr

Solr should be accessible at http://localhost:9033

## How to do the basics

### Indexing

Note that "today's file" is "the file that became available today", which 
will have _yesterday's_ date embedded in it. If you use these scripts you 
don't have to worry about any off-by-one errors. 

Re-run today's file: 
* `bin/catchup_today <optional_log_file>`

Run all the update files since a given date (YYYYMMDD):
* `bin/catchup_since 20220302`

Re-build the entire index based on the last full file, making sure 
everything is up-to-date:
* `bin/fullindex <optional_log_file>`

Note that the fullindex file _does not contain the updates from the update 
file with the same embedded date_! The `fullindex` script takes care of that, 
but 
if running stuff by hand keep in mind that you need to index the full file 
and the update file for that day as well.

### Add a new field

Adding a field requires two things:
  * adding a `to_field` definition in an indexing file
  * adding the field definition to the solr schema file `schema.xml`

After that, of course, you need to get the solr conf directory on the 
catalog indexing solr updated, restart that solr, and then reindex 
everything. 

While solr support for dynamic fields has gotten pretty good, we've never 
used it.


## Scripts

`bin/` holds scripts for indexing marc files. 98% of it is 
    high-ceremony bash stuff to find the "correct" jruby file, do date 
    arithmetic, find the zephir and delete files, etc. 

See [`bin/README.md`](bin/README.md) for more details.

TODO: Take the whole `bin/` mess apart and build all the date arithmetic in a 
ruby cli based on `dry-cli` or `thor` or something.

TODO: Add in non-hardcoded mechanisms for dictating where the marc/delete 
files will be, where the redirect file will be, etc.


## Structure of this repository

* [`bin/`](bin/) has all the scripts that control indexing, most of which is 
  actually horrendous date-arithmetic and environment switches from back 
  when the HT and UMich indexing were one system.
* [`indexers`](indexers/) would more appropriately be called "indexing 
  rules". It contains all the traject rules for turning a marc record into 
  a solr document, independent of the source of the marc record or where 
  it's being written to.
  * The organization of this dir reflects the HT/UMich joint code policy 
    long after it's no longer in place
  * **Order matters** when loading these files. In particular, the file 
    [`indexers/common.rb`](indexers/common.rb) has a ton of `require` 
    statements, settings, etc., and most of the other files assume that 
    stuff is all defined. 
* [`readers/`](readers/) have a variety of files that contain nothing but 
  traject settings that specify what reader to use. We use 
  newline-delimited-marc (`ndj`) but others are available for running test 
  files.
* [`writers/`](writers/), similarly, has files with traject settings for 
  different writers.  This might involve pushing the resulting documents 
  to solr (as in `localhost.rb`, which actually uses SOLR_URL), pushing to 
  a local file for human (`debug.rb`) or machine (`json.rb`) inspection, 
  or doing nothing at all (`null.rb`) for benchmarking.
* [`lib/`](lib/) contains all the code called by the indexing code. The 
  organization is...not so much organized at all. See that directory for 
  more info.

### Special file locations in this repo

`lib` is put into the search path, so one can `require` those file directly.

`lib/translation_maps` is automatically searched for translation map files 
(`.yaml`, `.rb`, or `.ini`) when they are referenced either by explicitly 
creating one (with `Traject::TranslationMap.new`) or implicitly created 
from an `extract_marc` (e.g., `extract_marc('1004:1104:1114', 
translation_map: 
'ht/relators')`). Note that all translation maps are cached so loading it 
more than once isn't a big deal. 


## Outside resources necessary for indexing

In addition to the obvious target solr instance, the indexing process pulls 
data from a number of external sources:

  * Mapping of collections to institution names. This is pulled byt the 
    script [bin/get_collection_map.rb](bin/get_collection_map.rb) from the 
    database tables `ht_institutions` and `ht_collections` and is cached 
    locally in `lib/translation_maps/ht`.
  * The `holdings_htitem_htmember` database table for print holdings
  * The `oclc_concordance` table for adding in canonical OCLC numbers
  * The file for the current month in 
    `/htapps/babel/hathifiles/catalog_redirects/redirects` for setting up 
    redirects.

TODO: Get the rights info from `rights_current` so it's up-to-date. It 
would be nice if `rights_current` had an index on the whole HTID instead 
of us having to split out the namespace...

## Database access

...is controlled by [`lib/ht_traject/ht_dbh.rb`]
(lib/ht_traject/ht_dbh.rb) with passwords/etc. in `lib/ht_secure_data.rb` 
(not in this repo, obviously). 

TODO: Put connection/ authentication info in ENV (and/or eventually k8s 
secrets)

## Environment variables

  * `SOLR_URL` with the solr _core_ URL (i.e, ending in `/catalog`)
  * `REDIRECT_FILE` (optional) if you don't want to use the default 
    redirect file
  * `NO_DB` if you want to skip all the database stuff. Useful for testing.

TODO: Add an env variable to skip using the redirect file as well.

TODO: Change to use `dotenv`?

TODO: Add environment variables for file locations

## A quick, high-level overview of how traject works

(the nerd version)

`traject` is really designed to be run from the command line, which makes 
things like testing a pain.

The lifecycle is:
  * a new `Traject::Indexer` is created, more-or-less blank.
  * each file passed to the `traject` command with a `-c` is read and
    subjected to `indexer.instance_eval`. Note that this causes closures 
    to be created for any lambdas defined in those files.
    * a `to_field` or `each_record` call adds the given proc/lambda to the 
      list of Things To Do in the indexer. These are run _in order_ for 
      every record. 
    * Note that macros (like the traject-provided `extract_marc`) actually 
      return a lambda, so `to_field 'id', extract_marc('001')` is just a 
      mapping from a name to a lambda. 
    * As of traject 3.0, you can stack an arbitrary number of lambdas/procs
      on a `to_field` call, optionally culminating with a block. This allows 
      post-processing calls like `first_only` to work.
    * Once all the files have been read and processed, it makes a reader 
      and a writer and starts processing the input records in turn and 
      spitting them out to the writer. 

### Traject "gotchas" / hints

* **THE ACCUMULATOR MUST BE CHANGED IN-SITU**. This is the one that messes 
  people up. Methods like `map` _will have no effect_ because they return 
  a new array. You must use things like:
  * `map!`, `reject!`, `select!`, etc.
  * `concat` (which should be a `!` method but isn't)
  * `replace` (ditto)
* **Scopes**: The `accumulator` exists only during the processing of a
  single `to_field`. The `context` lasts throughout the processing of a
  single record.  
* The basic structure is `to_field(field_name, lambdas/procs) &optional_block}`. The 
  list of lambdas is optional, as is the final block, but you need at 
  least one macro or the block. 
* Every proc/lambda (and the final block) must have the signature `(record, 
  accumulator_array, 
  traject_context_object)` or just `(record, accumulator_array)`. A 
  traject 'macro' is just a method that returns a lambda with that structure.
* Everything is pass-by-reference -- the record, acc, and context are all 
  the same as you go down the list of lambdas. Thus, as noted above, the 
  accumulator must be changed in-place.
* The context keeps track of where in the configuration files things are 
  defined (for error reporting), but also two important areas.
  * `context.clipboard` is simply a hash where you can store things for later.
  * `context.output_hash` is the actual mapping of field name to value -- 
    this is what's actually sent to the writer and then onto solr (or a 
    debug file or whatever). 
