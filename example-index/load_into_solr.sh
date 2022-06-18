#!/bin/bash

SOLR_URL="http://localhost:9033/solr/catalog"
input="/tmp/solrdocs.jsonl"
echo "Indexing records into Solr..."
nrec=$(cat $input | wc -l)
i=0
while IFS= read -r line
do
  let i++
  cat <<-EOT | curl -s -X POST -H "Content-Type:application/json"  --data-binary @- "$SOLR_URL/update/json/docs" > /dev/null
  [$line]
	EOT
  if (( $i % 50 == 0 || $i == $nrec )); then
    echo -ne "$i / $nrec records indexed\r"
  fi
done < "$input"
echo 

echo "Committing"
curl -s -H "Content-Type: application/json" -X POST -d'{"commit": {}}' "$SOLR_URL/update?wt=json"
echo "Done"
