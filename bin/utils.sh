function solr_url() {
    if [[ -z $SOLR_URL ]]; then
	SOLR_URL="http://localhost:9033/solr/catalog"
    fi
    echo $SOLR_URL
}

function find_marc_file_for_date() {
    local datestr=$1
    local datadir=$2
    echo "${datadir}/zephir_upd_${datestr}.json.gz"
}

function find_del_file_for_date() {
    local datestr=$1
    local datadir=$2
    echo "${datadir}/zephir_upd_${datestr}_delete.txt.gz"
}


function log() {
    local msg=$1
    local file=$2
    if [ -z $file ]; then
	echo $msg
    else
	[[ ! -f $file ]] && touch $file
	echo $msg >> $file 2>&1
    fi
}

function commit() {
    log "Commiting"
    curl -H "Content-Type: application/xml" -X POST -d'<commit/>' "$SOLR_URL/update?wt=json"
}

function empty_solr() {
    log "Emptying"
    curl -H "Content-Type: application/xml" -X POST -d"<delete><query>*:*</query></delete>" "$SOLR_URL/update?wt=json"
}
