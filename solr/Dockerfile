FROM solr:8.11

LABEL org.opencontainers.image.source https://github.com/hathitrust/hathitrust_catalog_indexer

ENV SOLR_PORT=9033

COPY --chown=solr:solr . /var/solr/data
# COPY --chown=solr:solr ./examples /examples
