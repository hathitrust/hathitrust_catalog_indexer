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
git clone https://github.com/hathitrust/hathitrust_catalog_indexer
cd hathitrust_catalog_indexer
docker-compose build
docker-compose up -d solr-sdr-catalog
docker-compose run --rm traject bundle install
```

### Generate Solr documents

Generate Solr documents given an input file of MARC records in JSON format, one per line:

```
docker-compose run --rm traject bundle exec bin/cictl index file --no-commit --writer=json input-marc-records.jsonl
```

Output will be in `debug.json`.

### Building a Sample Index Docker Image

This will build a docker image with a Solr core pre-loaded with a set of records.

* As above, put records you want to load in
  `example-index/records-to-index.jsonl`. Some records are included with this
repository; this is a set of 2,000 records from a variety of contributors that
were updated in HathiTrust on May 1, 2022.

* Then run:

```
docker build . -f example-index/Dockerfile -t my-sample-solr
```

and run e.g. `docker run -p 9033:9033 my-sample-solr`, or use in another
`docker-compose.yml`, etc.

A multi-platform (amd64/arm64) image with the sample records pre-loaded is
available:

```
docker pull ghcr.io/hathitrust/catalog-solr-sample
```

The sample HathiTrust catalog records are made available for development and
testing purposes only, and are not intended for further re-use in other
contexts.

### Index one file into Solr

Index a file of records without using ~~the database or~~ hardcoded filesystem paths:

```
# get some sample records somehow
docker-compose run --rm traject bundle exec bin/cictl index file examples/sample_records.json.gz
```

### Do a full index

Zephir records for the last monthly up to the current date should be in `examples`:

```bash
docker-compose run --rm traject bundle exec bin/cictl index all
```

### Query Solr

Solr should be accessible at http://localhost:9033

## Using with other projects via docker

Start solr and index as above. In the other project, ensure `docker-compose.yml` contains e.g.:

```yaml
services:
  web:
    build: .
    ports:
      - "3000:3000"
    # Add this networks entry to the service that needs to reach solr
    networks:
      - catalog_indexer

# Add this network information
networks:
  catalog_indexer:
    external: true
    # If you checked out into another directory than
    # 'hathitrust_catalog_indexer', adjust to match
    # match (appending '_default')
    name: hathitrust_catalog_indexer_default
```

If you checked out into another directory than `hathitrust_catalog_indexer`,
adjust the name of the network above to match.

This will ensure the application uses the solr running from this docker network
network (i.e. the one started with `docker-compose up` from this repository).
Solr should be reachable via the `solr-sdr-catalog` hostname.

## How to do the basics
### Date-Independent Indexing

For use in production environments where daily and monthly indexing are ongoing activities,
we enable the indexer to maintain state by writing "journal" files: empty datestamped
files in a known location (`JOURNAL_DIRECTORY`). The command `cictl index continue` does whatever
full or daily indexing is appropriate given the state of the journals.

Note that all of the `cictl index *` commands write journal files, with the exception of
`cictl index file` which takes only an `upd` MARC file rather than a MARC-deletes pair, and is not
expected to be used in an environment where date independence is in force.

### Putting a new solr configuration into place

* On `beeftea-2`, go to `/htsolr/catalog/bin/ht_catalog_indexer` and `git 
  pull` to get up to date
* Shut down the catalog indexing solr with `systemctl stop 
  solr-current-catalog`. 
* Copy the new configuration over:
  * `cd /htsolr/catalog/cores/catalog`
  * `rm -rf conf`
  * `rm core.properties`
  * `cp -r /htsolr/catalog/bin/ht_catalog_indexer/solr/catalog/conf .`
* (Optional) If your new solr config requires a full reindex, go ahead and 
  get rid of the data with `rm -rf data`
* Fire solr back up: `systemctl start solr-current-catalog`
* Give it a minute and then go to `http://beeftea-2.umdl.umich.edu:9033/solr` to make sure the core came back up.
* Do whatever indexing needs doing.

### Indexing

Note that "today's file" is "the file that became available today", which 
will have _yesterday's_ date embedded in it.

Re-process today's file: 
* `bin/cictl index today`

Processes all deletes/marcfiles with a date on or after YYYYMMDD in its name sequentially
* `bin/cictl index since 20220302`

Re-build the entire index based on the last full file, making sure 
everything is up-to-date:
* `bin/cictl index all`

Note that the fullindex file _does not contain that day's updates_ (e.g., on 
July 1, you need to index both the `zephir_full_20230630` file _and_ the `zephir_upd_20230630` file. 
The `index all` command takes care of that, but 
if running stuff by hand keep in mind that you need to index the full file 
and the update file for that day as well.

### Add a new field

Adding a field requires two things:
  * adding a `to_field` definition in an indexing file
  * adding the field definition to the solr schema file `schema.xml`

After that, of course, you need to get the solr conf directory on the 
catalog indexing solr updated, restart that solr, and then reindex 
everything. See [solr/README.md](solr/README.md).

While solr support for dynamic fields has gotten pretty good, we've never 
used it.


## Scripts

The main driver script is `bin/cictl`:

```
> bundle exec bin/cictl help
Commands:
  cictl delete SUBCOMMAND ARGS  # Delete some or all Solr records
  cictl help [COMMAND]          # Describe available commands or one specific...
  cictl index SUBCOMMAND ARGS   # Index a set of records from a file or date
  cictl pry                     # Open a pry-shell with environment loaded

Options:
  [--verbose], [--no-verbose]  # Emit 'debug' in addition to 'info' log entries
  [--log=<logfile>]            # Log to <logfile> instead of STDOUT/STDERR
```

The `index` command has a number of possibilities:
```
> bundle exec bin/cictl help index
Commands:
  cictl index all             # Empty the catalog and index the most recent m...
  cictl index continue        # index all files not represented in the indexe...
  cictl index date YYYYMMDD   # Run the catchup (delete and index) for a part...
  cictl index file FILE       # Index a single file
  cictl index help [COMMAND]  # Describe subcommands or one specific subcommand
  cictl index since YYYYMMDD  # Run all deletes/includes in order since the g...
  cictl index today           # Run the catchup (delete and index) for last n...

Options:
  [--reader=READER]  # Reader name/path
  [--writer=WRITER]  # Writer name/path
```

The `delete` command has fewer subcommands:
```
> bundle exec bin/cictl help delete
Commands:
  cictl delete all             # Delete all records from the Solr index
  cictl delete file FILE       # Delete records from a single file
  cictl delete help [COMMAND]  # Describe subcommands or one specific subcommand
```

TODO: Add in non-hardcoded mechanisms for dictating where the marc/delete 
files will be, where the redirect file will be, etc.


## Structure of this repository

* [`bin/`](bin/) contains the `cictl` indexing CLI.
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
  newline-delimited-marc (`jsonl`) but others are available for running test 
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

  * Mapping of collections to institution names. This is pulled by the 
    script [bin/get_collection_map.rb](bin/get_collection_map.rb) from the 
    database tables `ht_institutions` and `ht_collections` and is cached 
    locally in `lib/translation_maps/ht`. *(FIXME: should `cictl` expose this functionality?)*
  * The `holdings_htitem_htmember` database table for print holdings
  * The `oclc_concordance` table for adding in canonical OCLC numbers
  * The file for the current month in `/htapps/archive/redirects` for setting up redirects.

TODO: Get the rights info from `rights_current` so it's up-to-date. It 
would be nice if `rights_current` had an index on the whole HTID instead 
of us having to split out the namespace...

## Database access

Connection string is exposed by the `Services` object based on environment variables
and `config/env`. The defaults in the repository suffice for testing under Docker only.

## Environment variables

  * `DDIR` data directory, defaults to `/htsolr/catalog/prep`
  * `JOURNAL_DIRECTORY` location of journal files (see Date-Independent Indexing above) defaulting
    to `journal/` inside the repo directory.
  * `LOG_DIR` where to store logs, defaults to `logs/` inside the repo directory.
  * `MYSQL_HOST`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` *required* unless run with `NO_DB`.
  * `NO_DB` if you want to skip all the database stuff. Useful for testing. Implied by `NO_EXTERNAL_DATA`.
  * `NO_EXTERNAL_DATA` combines `NO_DB`, `NO_REDIRECTS`
  * `NO_REDIRECTS` do not read catalog redirects file. Implied by `NO_EXTERNAL_DATA`.
  * `REDIRECT_FILE` (and the now-*deprecated* `redirect_file`) path to the redirect file.
    Default is `REDIRECTS_DIR/redirects_YYYYMM.txt.gz`.
  * `REDIRECTS_DIR` (no default) should be set to `/htapps/archive/redirects` or wherever hathifiles
    writes its catalog redirects output.
  * `SOLR_URL` *(required)* with the solr _core_ URL (i.e, ending in `/catalog`)

### Prometheus Pushgateway Environment Variables

  * `JOB_NAME` if not set defaults to the `cictl` command, e.g., `index_continue` from `cictl index continue`.
  * `JOB_SUCCESS_INTERVAL` handled by `PushMetrics`, no defaults set by this repository.
  * `PUSHGATEWAY` set to `http://pushgateway:9091` in the `docker-compose` file, otherwise no default.
  

### Internal-use Environment Variables

  These are used internally, mainly for testing. They are not exposed by the `Services` object.

  * `CICTL_SEMANTIC_LOGGER_SYNC` forces SemanticLogger to run on the main thread
    in order to mitigate testing headaches.
  * `CICTL_ZEPHIR_FILE_TEMPLATE_PREFIX` for test fixtures, overrides default "zephir".


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
