#!/bin/bash
set -uo pipefail

SOLR_URL="${SOLR_URL:-http://localhost:9033/solr/catalog}"
INPUT_FILE="${INPUT_FILE:-/tmp/solrdocs.jsonl}"
BATCH_SIZE="${BATCH_SIZE:-100}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Index documents from a JSONL file into a SolrCloud collection.

Options:
  -u, --url URL         Solr collection URL (default: $SOLR_URL)
  -i, --input FILE      JSONL input file, one document per line (default: $INPUT_FILE)
  -b, --batch-size N    Documents per POST request (default: $BATCH_SIZE)
  -h, --help            Show this help

Environment variables SOLR_URL, INPUT_FILE, and BATCH_SIZE are used as defaults.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--url)        SOLR_URL="$2";   shift 2 ;;
    -i|--input)      INPUT_FILE="$2"; shift 2 ;;
    -b|--batch-size) BATCH_SIZE="$2"; shift 2 ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: input file not found: $INPUT_FILE" >&2
  exit 1
fi

post_batch() {
  local json_array="$1"
  local response http_code body

  response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    --data-binary "$json_array" \
    "$SOLR_URL/update/json/docs")

  http_code=$(tail -n1 <<< "$response")
  body=$(sed '$d' <<< "$response")

  if [[ "$http_code" != "200" ]]; then
    echo ""
    echo "Error: Solr returned HTTP $http_code" >&2
    echo "$body" >&2
    return 1
  fi

  if echo "$body" | grep -q '"status":0'; then
    return 0
  else
    echo ""
    echo "Error: unexpected Solr response:" >&2
    echo "$body" >&2
    return 1
  fi
}

nrec=$(wc -l < "$INPUT_FILE")
echo "Indexing $nrec records from $INPUT_FILE in batches of $BATCH_SIZE..."

indexed=0
errors=0
batch=""
batch_doc_count=0

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue

  if [[ -n "$batch" ]]; then
    batch="${batch},${line}"
  else
    batch="$line"
  fi
  batch_doc_count=$((batch_doc_count + 1))

  if (( batch_doc_count >= BATCH_SIZE )); then
    if post_batch "[$batch]"; then
      indexed=$((indexed + batch_doc_count))
    else
      errors=$((errors + batch_doc_count))
    fi
    echo -ne "$indexed / $nrec indexed\r"
    batch=""
    batch_doc_count=0
  fi
done < "$INPUT_FILE"

if [[ -n "$batch" ]]; then
  if post_batch "[$batch]"; then
    indexed=$((indexed + batch_doc_count))
  else
    errors=$((errors + batch_doc_count))
  fi
fi

echo "$indexed / $nrec indexed"

echo "Committing..."
commit_response=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"commit": {}}' \
  "$SOLR_URL/update?wt=json")

commit_code=$(tail -n1 <<< "$commit_response")
if [[ "$commit_code" != "200" ]]; then
  echo "Error: commit failed with HTTP $commit_code" >&2
  sed '$d' <<< "$commit_response" >&2
  exit 1
fi

echo "Done. $indexed documents indexed successfully${errors:+, $errors failed}."
[[ $errors -gt 0 ]] && exit 1
exit 0