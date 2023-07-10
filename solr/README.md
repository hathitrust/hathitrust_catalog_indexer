# Deploying a new solr configuration

All indexing is done on the "reindexing solr", currently
`beeftea-2`. The complete solr install (including the index) is copied
every night to the production servers, which we never actually need to 
touch.

Deploying a new solr configuration is as follows. First, in
`/htsolr/catalog/bin/ht_catalog_indexer`, check that there aren't any
unexpected uncommitted changes with `git status`. It's expected that the
translation maps such as `collection_code_to_original_from.yaml` will have
changed, as they're generated from the database on each run. Stash or commit
any other changes as needed. Then, get the new code:

```shell
git pull origin main
```

To prevent the catalog from being released before we verify it is correct:

```shell
touch /htsolr/catalog/flags/STOPCATALOGRELEASE 
```

Then: stop solr, move the existing catalog core aside, copy the new schema in place,
`chmod` the new core so Solr can write to it, and restart solr:

```shell
cd /htsolr/catalog/cores
systemctl stop solr-current-catalog
mv catalog "catalog_$(date +%Y%m%d)"
rm "catalog_$(date %Y%m%d)/core.properties" # ensure solr doesn't load the backup as a core
cp -r /htsolr/catalog/bin/ht_catalog_indexer/solr/catalog .
chmod o+w /htsolr/catalog/cores/catalog
sudo systemctl start solr-current-catalog; sleep 10
```

Do a basic check to see if it's up and returns HTTP 200 with an empty)set of documents:

```shell
curl 'http://localhost:9033/solr/catalog/select?q=*:*&wt=json' | json_xs
```

Then, do a full catalog index:
```shell
cd /htsolr/catalog/bin/ht_catalog_indexer
/usr/bin/nohup bin/cictl index all --log="logs/full_$(date +%Y%m%d).txt" &
```

You can follow the logfile listed above for progress; the full index typically takes 
several hours.

You can then point a catalog instance directly at this "catalog build" solr to ensure
everything looks OK. Change (for example) `/htapps/dev-1.catalog/web/conf/solrURL.ini`
to contain:

```ini
url = http://beeftea-2:9033/solr/
full_url = http://beeftea-2:9033/solr/catalog/
```

Then, remove the set-aside copy and the flag stopping release:

```
rm -rf "/htsolr/catalog/cores/catalog_$(date +%Y%m%d)"
rm /htsolr/catalog/flags/STOPCATALOGRELEASE
```

N.B.: If, after the new catalog is released, you discover problems and need to roll back, 
this can be done by manually adjusting the catalog release script 
`/l/local/bin/index-release-catalog` on `squishee-2` and `slurpee-2` to point 
to a snapshot from a particular previous date.


