# Deploying a new solr configuration

All indexing is done on the "reindexing solr", currently
`beeftea-2`. The complete solr install (including the index) is copied
every night to the production servers, which we never actually need to 
touch.

Deploying a new solr configuration is as follows:

```shell
cd /htsolr/catalog/bin/ht_catalog_indexer
git pull origin main # get the new code
touch /htsolr/catalog/flags/STOPCATALOGRELEASE 
cd /htsolr/catalog/cores
systemctl stop solr-current-catalog
mv catalog "catalog_$(date %Y%m%d)"
cp -r /htsolr/catalog/bin/ht_catalog_indexer/solr/catalog .
systemctl start solr-current-catalog; sleep 10
# Sanity check to see if it's up and returns a 200 (empty) set of documents
curl 'http://localhost:9033/solr/catalog/select?q=*:*&wt=json' | json_xs
cd /htsolr/catalog/bin/ht_catalog_indexer
/usr/bin/nohup bin/fullindex "logs/full_$(date +%Y%m%d).txt"
# wait a few hours
# point a catalog instance directly at beeftea-2 to make sure it works well
rm -rf "/htsolr/catalog/cores/catalog_$(date %Y%m%d)"
rm /htsolr/catalog/flags/STOPCATALOGRELEASE

```


