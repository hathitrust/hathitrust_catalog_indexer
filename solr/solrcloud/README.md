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

### Prepare configuration

Zip up the complete core configuration, including `schema.xml` and anything it references. There should not be any subdirectories in the zip; i.e. the files should not be in the `conf` directory.

For example for [the HathiTrust catalog](https://github.com/hathitrust/hathitrust_catalog_indexer):

```bash
git clone https://github.com/hathitrust/hathitrust_catalog_indexer
cd hathitrust_catalog_indexer/solr/catalog/conf
zip -r ../ht_catalog_configset.zip
cd ..
```

### Upload configuration

Ensure the port forwarding is running and that you have an environment variable with the Solr admin password, then use curl to upload the configuration:

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
echo $(kubectl -n $SOLRCLOUD get secret htsolr-solrcloud-security-bootstrap -o jsonpath='{.data.solr}' | base64 -d)
```

With traject, the `SolrJsonWriter` can use HTTP basic authentication by using a solr URL of the form `http://user:pass@host/solr` (see https://www.rubydoc.info/gems/traject/Traject/SolrJsonWriter). Note this may cause issues with non-alphanumeric characters in the password, and URL-encoding these  characters doesn't appear to work with traject and the underlying httpclient gem it uses. If need be, change the password from the Solr admin interface under "security"; using a `!` as the required special character seems to work.

If you wish to reach this solr from inside another Docker container, one option that worked for me is setting up the port forward, using [`network_mode: host`](https://docs.docker.com/compose/compose-file/compose-file-v3/#network_mode) in your `docker-compose.yml`, and using http://user:pass@localhost:8983 for your Solr URL.  [How to Connect to Localhost Within a Docker Container](https://www.howtogeek.com/devops/how-to-connect-to-localhost-within-a-docker-container/) gives some more options.

Another option would be to run the indexing in minikube and reach Solr via the service in Kubernetes, e.g. `http://$SOLRCLOUD-solrcloud-common/solr/catalog` (note the Solr operator configures this service on port 80, not the Solr default port 8983).

## More info

While this should be sufficient for getting started with solr cloud and trying it out; it's definitely not sufficient for setting up solrcloud in production; we'll need to configure options for persistent storage, security, logging, monitoring, performance, etc.

* Documentation on the [SolrCloud CRDs](https://apache.github.io/solr-operator/docs/solr-cloud/solr-cloud-crd.html) (custom resource definitions)
* Documentation on the [solr helm chart](https://artifacthub.io/packages/helm/apache-solr/solr)

## Solr Upgrade from 8.11.2 to 8.11.4. 

It is a minor upgrade within the same version family. In the case of the Catalog, re-indexing could be fine.

### Solr upgrade checklist:

* Review Solr 8.11.4 release notes and CHANGES.txt for anything that affects the setup: https://solr.apache.org/docs/8_11_4/changes/Changes.html
* Check the current Java version (Solr8 supports Java 8-11)
* Verify that the current Solr operator supports the Solr version you wish to upgrade. 
* Confirm your Solr Operator supports Solr 8.11.4; we only need to move to upgrade the operator if you are moving to Solr 9.x
* Update the Solr version on [Solr custom resource](https://github.com/hathitrust/argocd-kubeadmin/tree/main/lib) 
```
solrImage: {
        repository: 'http://ghcr.io/hathitrust/catalog-solr ',
        tag: 'solrcloud-8.11.2',
      },
      .
      .
      .
      .
image: {
  repository: 'solr',
  tag: '8.11.2',
},
```
* Upgrade the Solr Docker image tag: https://github.com/hathitrust/hathitrust_catalog_indexer/blob/main/solr/solrcloud/Dockerfile 
* Back up the SolrCloud (collection) cluster before upgrading.
* Back up Zookeeper state

### **Create a Snapshot (Backup)**

We have tried two techniques to back up a Solr collection in SolrCloud:

**Using the Solr Operator**: In the Solr [custom resource](https://github.com/hathitrust/argocd-kubeadmin/blob/main/environments/infrastructure/metadata-processing-testing-solrcloud/main.jsonnet), 
we have added the `backupRepositories` entry to enable backups of the collections on the Solr cluster.
Solr operator will include a backup and restore feature that can be used to create backups of Solr collections. 
Find [here](https://github.com/apache/solr-operator/blob/main/docs/solr-backup/README.md) 
additional information to back up a collection in SolrCloud. 

For backup in Kubernetes, we have created a shared filesystem path (location) that is accessible from all Solr pods in the cluster.
Solr will write the backup files to that location.

To access the Solr backups, SSH into any server with access to `htprep`. 
The complete path for all backups is `/htprep/metadata_workflow_testing/catalog_backups/cloud/metadata-processing-testing/backups/`.

* After that, we can create a backup by defining the following resources in a yaml file. 

```yaml
apiVersion: solr.apache.org/v1beta1
kind: SolrBackup
metadata:
  name: backup-test-20250520
  namespace: metadata-processing-testing
spec:
  repositoryName: "catalog-backup"
  SolrCloud: metadata-processing-testing
  collections:
    - catalog
```
* Use the command below to create the backup. 

```bash
`kubectl -n metadata-processing-testing apply backup-test-20250520.yml` 
```

**Solr's Backup API**: This is a built-in API that allows you to create a full backup of a Solr collection. 

The API will back up the collection, but not the configsets.

```bash
curl "http://localhost:8983/solr/admin/collections?action=BACKUP&name=catalog_snapshot_2025_05_19&collection=catalog&location=/backups"


name: the snapshot name
collection: collection name
location: The shared filesystem path
```

### Command to check the backup status

- **How to check the backup status?**
```bash
kubectl -n metadata-processing-testing get solrbackup backup-test-20250520 -o jsonpath='{.status.successful}'
```
- **Command to see the list of backups**

```bash
 kubectl -n metadata-processing-testing get solrbackups
 ```

- **How much space is needed to store the index files and metadata at the path specified in the location?**

We need enough free space to store:
- All index segments for the collection (including replicas). Solr doesn’t back up all replicas; 
it backs up only one per shard. But it still must copy the full shard data to the backup location.
- Snapshot metadata, so backup_size => index size of the collection


- **Use Solr metrics API to get the collection size:**

```bash
 curl -u admin:$SOLR_PASS "http://localhost:53428/solr/admin/metrics?group=core&prefix=INDEX.sizeInBytes&wt=json" 
 ```

### Backing up Zookeeper state

It is important to have backup of the cluster coordination state to:

- Recovery from a disaster
- Migration: When moving to a new cluster
- Version Control: Snapshot configsets or cluster before changes
- Audit: To preserve the state at a specific point in time.

### Manual Backup kubectl:

**Backup Zookeeper stage**

Open a terminal in a Zookeeper pod

```bash
kubectl -n metadata-processing-testing exec metadata-processing-testing-solrcloud-zookeeper-0 -it -- /bin/bash
```

Export Zookeeper tree using zkCli.sh

```bash
zkCli.sh -server metadata-processing-testing-solrcloud-zookeeper-0.metadata-processing-testing-solrcloud-zookeeper-headless.metadata-processing-testing.svc.cluster.local:2181,metadata-processing-testing-solrcloud-zookeeper-1.metadata-processing-testing-solrcloud-zookeeper-headless.metadata-processing-testing.svc.cluster.local:2181,metadata-processing-testing-solrcloud-zookeeper-2.metadata-processing-testing-solrcloud-zookeeper-headless.metadata-processing-testing.svc.cluster.local:2181 get /configs/catalog > catalog_config.txt
```

#### Manual backup configsets

To run solr `zk downconfig` in a Kubernetes-based SolrCloud cluster, you’ll need to run the command from inside a Solr pod

Open a terminal into a Solr pod

```bash
kubectl -n metadata-processing-testing exec metadata-processing-testing-solrcloud-0 -it -- /bin/bash
```

Explore what is in ZK `solr zk ls -z <zk-hosts> /configs`

e.g. 

```bash
solr zk ls -z metadata-processing-testing-solrcloud-zookeeper-0.metadata-processing-testing-solrcloud-zookeeper-headless.metadata-processing-testing.svc.cluster.local:2181,metadata-processing-testing-solrcloud-zookeeper-1.metadata-processing-testing-solrcloud-zookeeper-headless.metadata-processing-testing.svc.cluster.local:2181,metadata-processing-testing-solrcloud-zookeeper-2.metadata-processing-testing-solrcloud-zookeeper-headless.metadata-processing-testing.svc.cluster.local:2181 /configs
```

The input of the command below will be all the configset in the cluster. e.g. _default, catalog, catalog_logs

Inside the Solr pod, run the command to download the configset

```bash
solr zk downconfig -z metadata-processing-testing-solrcloud-zookeeper-0.metadata-processing-testing-solrcloud-zookeeper-headless.metadata-processing-testing.svc.cluster.local:2181,metadata-processing-testing-solrcloud-zookeeper-1.metadata-processing-testing-solrcloud-zookeeper-headless.metadata-processing-testing.svc.cluster.local:2181,metadata-processing-testing-solrcloud-zookeeper-2.metadata-processing-testing-solrcloud-zookeeper-headless.metadata-processing-testing.svc.cluster.local:2181 -n catalog -d /tmp/catalog_configsetbackup_2025_05_19
```

* -z list of zookeeper host
* -n name of the configset
* -d the local directory to download the configset

Copy Snapshot to Target Environment

```bash
kubectl cp -n metadata-processing-testing metadata-processing-testing-solrcloud-0:/tmp/catalog_configsetbackup_2025_05_19 Downloads/catalog_configsetbackup_2025_05_19
```

### Restore the back up

We will need to understand better how to do that. 
3- Restore Snapshot in Target Environment

```bash
curl "http://localhost:8983/solr/admin/collections?action=RESTORE&name=catalog_snapshot_2025_05_19&collection=catalog&location=/backups"
```


Note: For some update it will make sense to create a different namespace for the new release


## Next Steps

We will need to understand the following for configuring something in our production k8s clusters: 

* Storage via persistent volume claims
* Configuring an ingress
* Configuring metrics for prometheus (SolrPrometheusExporter custom type)
* Configuring for sufficient performance -- indexing via minikube is very slow; it wasn't clear if that was because of running multiple solrs at once on my personal machine, the way that minikube handles local storage, or something else.
* Restoring a Solr index (Use full-text search for this experiment)
* Workflow to back up and restore Zookeeper state
We could also investigate the backup/snapshots option for a potentially more supported way of setting up an index release workflow (i.e. take a snapshot, back it up, restore it, swap that in)



https://solr.apache.org/operator/articles/explore-v030-gke.html has a good introduction to some of the concerns. It discusses some about high availability as well as configuring prometheus exporters.
