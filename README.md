Index a file of records without using the database or hardcoded filesystem paths:

```bash

docker-compose build
docker-compose run --rm traject bundle install
docker-compose run --rm traject bundle exec fetch_new_hlb ./lib/translation_maps
# get some sample records somehow
docker-compose run traject bundle exec bin/index_file examples/sample_records.json.gz
# ensure documents are committed
source bin/utils.sh; solr_url; commit
```
