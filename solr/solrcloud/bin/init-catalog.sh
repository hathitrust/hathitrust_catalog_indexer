#!/bin/bash
set -e

ZK_HOST="${ZK_HOST:-zoo1:2181}"
SOLR_HOST="${SOLR_HOST:-solr-sdr-catalog:9033}"
COLLECTION_NAME="${COLLECTION_NAME:-catalog}"
CONFIGSET_NAME="${CONFIGSET_NAME:-catalog-config}"
NUM_SHARDS="${NUM_SHARDS:-1}"
REPLICATION_FACTOR="${REPLICATION_FACTOR:-1}"
CONF_DIR="${CONF_DIR:-/catalog_config/conf}"
SAMPLE_DATA="${SAMPLE_DATA:-/catalog_config/solrdocs.jsonl}"

echo "Uploading configset '$CONFIGSET_NAME' to ZooKeeper at $ZK_HOST..."
/opt/solr/bin/solr zk upconfig \
  -n "$CONFIGSET_NAME" \
  -d "$CONF_DIR" \
  -z "$ZK_HOST"

echo "Checking if collection '$COLLECTION_NAME' already exists..."
EXISTING=$(curl -sf "http://$SOLR_HOST/solr/admin/collections?action=LIST" \
  | grep -c "\"$COLLECTION_NAME\"" || true)

if [ "$EXISTING" -gt 0 ]; then
  echo "Collection '$COLLECTION_NAME' already exists, skipping creation and data load."
else
  echo "Creating collection '$COLLECTION_NAME'..."
  curl -f "http://$SOLR_HOST/api/collections" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$COLLECTION_NAME\",
      \"config\": \"$CONFIGSET_NAME\",
      \"numShards\": $NUM_SHARDS,
      \"replicationFactor\": $REPLICATION_FACTOR
    }"
  echo ""
  echo "Collection '$COLLECTION_NAME' created successfully."

  if [ -f "$SAMPLE_DATA" ]; then
    echo "Loading sample data from $SAMPLE_DATA..."
    SOLR_URL="http://$SOLR_HOST/solr/$COLLECTION_NAME" \
    INPUT_FILE="$SAMPLE_DATA" \
      /usr/local/bin/load-into-solrcloud
  fi
fi