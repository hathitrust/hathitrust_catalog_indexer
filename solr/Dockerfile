FROM solr:6.6.5

LABEL org.opencontainers.image.source https://github.com/hathitrust/hathitrust_catalog_indexer

ENV SOLR_PORT=9033

COPY --chown=solr:solr . /opt/solr/server/solr/catalog
# COPY --chown=solr:solr ./examples /examples
