# Setup

```bash

docker-compose build
docker-compose up -d solr-sdr-catalog
docker-compose run --rm traject bundle install
docker-compose run --rm traject bundle exec fetch_new_hlb ./lib/translation_maps
```

## Index one file

Index a file of records without using the database or hardcoded filesystem paths:

```
# get some sample records somehow
docker-compose run traject bin/index_file examples/sample_records.json.gz
# ensure documents are committed
source bin/utils.sh; solr_url; commit
```

## Do a full index

Zephir records for the last monthly up to the current date should be in `examples`:

```bash

docker-compose run traject bin/fullindex
```

## Query Solr

Solr should be accessible at http://localhost:9033


