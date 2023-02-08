# Solr Cloud w/ Minikube

This describes how to set up a locally-running SolrCloud setup with [minikube](https://minikube.sigs.k8s.io) and the [Solr operator](https://solr.apache.org/operator/).

This roughly follows [the Solr operator tutorial](https://apache.github.io/solr-operator/docs/local_tutorial) but uses minikube instead of Docker for Mac with K8s. YMMV if you try with other desktop k8s options.

## Build a Docker image with custom jars

Before we begin, we'll need a solr image with our custom jars baked in. This is typically what's in the `lib` directory for the core in (alongside `data` and `conf`) in our current setup.
This already exists for the HathiTrust catalog indexer.

* For the HathiTrust catalog indexer and feddocs this is  `lucene-umich-solr-filters-7.2.1.1.1-SNAPSHOT.jar`
* For umich catalog indexing this is the contents of https://github.com/mlibrary/catalog_solr_index/tree/main/biblio/lib

To build an image based on solr 8.11.1 with the libraries baked in, put the jars you need in a directory called `lib`; then use a `Dockerfile` like:o

Your directory layout should look like:
```
$ ls -R .
.:
Dockerfile  lib

./lib:
lucene-umich-solr-filters-7.2.1.1.1-SNAPSHOT.jar
# or whatever other jars you need
```

```dockerfile
FROM solr:8.11.1

COPY --chown=solr:solr lib /var/solr/lib
```

Build it and push to GHCR with: 

```bash
# Set this to whatever organization/package you want to use
export IMAGE_REPO=ghcr.io/hathitrust/catalog-solr
docker build . -t $IMAGE_REPO:solrcloud-8.11.1
docker push $IMAGE_REPO:solrcloud-8.11.1
```

Make sure the image is public (go to the image; then to settings & change visibility if needed) -- the jars and solr config aren't sensitive, and by making the image public you don't need to worry about configuring a PAT for pulling the image.

## Install dependencies

* Install [minikube](https://minikube.sigs.k8s.io/docs/start/)
* Install [helm](https://helm.sh/docs/intro/install/)
* Install the Solr operator following instructions from the [solr operator quickstart](https://apache.github.io/solr-operator/docs/local_tutorial#install-the-solr-operator)

## Create a SolrCloud cluster

> **Warning**
> Don't use the options listed in the quickstart as 1) they reference an ingress controller we didn't use and 2) they don't set up authentication, which we need.

For now, use `helm` to install the cluster. set  `$SOLRCLOUD` to whatever you want to call the overall thing -- e.g. `catalog`, `feddocs`, `htsolr`, whatever. this assumes you'll call the solr cloud instance the same thing as the namespace you install it into.

```bash
export IMAGE_REPO=ghcr.io/hathitrust/catalog-solr
export SOLRCLOUD=htsolr
helm install $SOLRCLOUD apache-solr/solr --version 0.5.1 \
  --namespace $SOLRCLOUD \
  --create-namespace \
  --set image.repository=$IMAGE_REPO \
  --set image.tag=solrcloud-8.11.1 \
  --set solrOptions.javaMemory="-Xms300m -Xmx300m" \
  --set solrOptions.security.authenticationType="Basic"
```

See https://artifacthub.io/packages/helm/apache-solr/solr for other options you might need (e.g. `solroptions.javaopts`, `solroptions.loglevel`, etc)

You can watch the status of the cluster starting up:

```bash
kubectl -n $SOLRCLOUD get -w pod
```

Eventually (it may take a while) all solrs should be online. If all the solrs end up in a `CrashLoopBackOff` state, you can try:

```bash
kubectl -n $SOLRCLOUD rollout restart statefulset $SOLRCLOUD-solrcloud
```

(You may need to do this a couple times; the issue seems to be related to timeouts with readiness checks with so many things starting up in parallel.)

Once all the solrs are up and ready, you can connect to solr:

```bash
kubectl -n $SOLRCLOUD port-forward service/$SOLRCLOUD-solrcloud-common 8983:80
```

This will ask for a username and password, which SolrCloud has automatically configured for us. We can get the password with:

```bash
SOLR_PASS=$(kubectl -n $SOLRCLOUD get secret htsolr-solrcloud-security-bootstrap -o jsonpath='{.data.admin}' | base64 -d)
echo $SOLR_PASS
```

You can now go to http://localhost:8983 and log in with username `admin` and password from above. If you click on "Cloud" you should see three Solr nodes; if you click on "ZK Status" under cloud you should see status "green" with three ZooKeeper nodes.

## Upload configuration to Solr/ZooKeeper

Now that Solr is up and running, we need to get the configuration for our Solr core into Solr. We can do that using the [ConfigSet API](https://solr.apache.org/guide/8_11/configsets-api.html)

To date, we have only used static Solr configuration via a `solrconfig.xml` typically managed alongside the indexing configuration, rather than using the [Schema API](https://solr.apache.org/guide/8_11/schema-api.html) to dynamically define fields.

Make sure that `solrconfig.xml` references where you put the jars, typically:

```xml
<lib dir="${solr.solr.home}/../lib" regex=".*\.jar"/>
```

### Prepare configuration

Zip up the complete core configuration, including `schema.xml` and anything it references. There should not be any subdirectories in the zip; i.e. the files should not be in the `conf` directory.

For example for [the HathiTrust catalog](https://github.com/hathitrust/hathitrust_catalog_indexer):

```bash
git clone https://github.com/hathitrust/hathitrust_catalog_indexer
cd hathitrust_catalog_indexer/solr/catalog/conf
zip -r ../ht_catalog_configset.zip .
cd ..
```

### Upload configuration

Ensure the port forwarding is running and that you have an environment variable with the Solr admin password, then use curl to upload the configuration:

> **Warning**
> This will likely not work well if the config includes custom .jars. If so, the best course of action is either to bake them into the solr image (if they are unlikely to change) or to use the Solr plugin system (see https://github.com/mlibrary/solr-cloud-package-manager-demo)

```bash
CONFIGSET=ht_catalog_configset
curl -u admin:$SOLR_PASS -X PUT \
  --header "Content-Type: application/octet-stream" \
  --data-binary @$CONFIGSET.zip \
  "http://localhost:8983/api/cluster/configs/$CONFIGSET"
```

## Create a Collection

This will create a collection using the config you uploaded. A collection in SolrCloud roughly corresponds to a core in a standalone solr, but is potentially split into several shards and replicated across several nodes. This command creates a collection where there is a single shard, duplicated across all 3 solr nodes.

```bash
curl -u admin:$SOLR_PASS "http://localhost:8983/solr/admin/collections?action=CREATE&name=catalog&numShards=1&replicationFactor=3&maxShardsPerNode=2&collection.configName=$CONFIGSET"
```

This may take some time to return; once it completes you should be able to do e.g. 

```bash
curl -u admin:$SOLR_PASS "http://localhost:8983/solr/catalog/admin/ping"
```

## Index to SolrCloud

You should now be able to index and query just as you would to a standalone Solr, although you'll need to use HTTP basic authentication. By default you'll need to use the `admin` user to index; there is a `solr` user as well created by default that you can use for querying. You can get the password similar to how you got the admin password:

```bash
echo $(kubectl -n $SOLRCLOUD get secret $SOLRCLOUD-solrcloud-security-bootstrap -o jsonpath='{.data.solr}' | base66 -d)
```

With traject, the `SolrJsonWriter` can use HTTP basic authentication by using a solr URL of the form `http://user:pass@host/solr` (see https://www.rubydoc.info/gems/traject/Traject/SolrJsonWriter). Note this may cause issues with non-alphanumeric characters in the password, and URL-encoding these  characters doesn't appear to work with traject and the underlying httpclient gem it uses. If need be, change the password from the Solr admin interface under "security"; using a `!` as the required special character seems to work.

If you wish to reach this solr from inside another Docker container, one option that worked for me is setting up the port forward, using [`network_mode: host`](https://docs.docker.com/compose/compose-file/compose-file-v3/#network_mode) in your `docker-compose.yml`, and using http://user:pass@localhost:8983 for your Solr URL.  [How to Connect to Localhost Within a Docker Container](https://www.howtogeek.com/devops/how-to-connect-to-localhost-within-a-docker-container/) gives some more options.

Another option would be to run the indexing in minikube and reach Solr via the service in Kubernetes, e.g. `http://$SOLRCLOUD-solrcloud-common/solr/catalog` (note the Solr operator configures this service on port 80, not the Solr default port 8983).

## More info

While this should be sufficient for getting started with solr cloud and trying it out; it's definitely not sufficient for setting up solrcloud in production; we'll need to configure options for persistent storage, security, logging, monitoring, performance, etc.

* Documentation on the [SolrCloud CRDs](https://apache.github.io/solr-operator/docs/solr-cloud/solr-cloud-crd.html) (custom resource definitions)
* Documentation on the [solr helm chart](https://artifacthub.io/packages/helm/apache-solr/solr)

## Next Steps

We will need to understand the following for configuring something in our production k8s clusters: 

* Storage via persistent volume claims
* Configuring an ingress
* Configuring metrics for prometheus (SolrPrometheusExporter custom type)
* Configuring for sufficient performance -- indexing via minikube is very slow; it wasn't clear if that was because of running multiple solrs at once on my personal machine, the way that minikube handles local storage, or something else.

We could also investigate the backup/snapshots option for a potentially more supported way of setting up an index release workflow (i.e. take a snapshot, back it up, restore it, swap that in)

https://solr.apache.org/operator/articles/explore-v030-gke.html has a good introduction to some of the concerns. It discusses some about high availability as well as configuring prometheus exporters.
