FROM solr:10.0.0

ENV SOLR_PORT=9033

# analysis-extras is needed for the ICU folding filter, scripting is needed for the JavaScript update processor.
ENV SOLR_MODULES=analysis-extras,scripting

# Load JARs inside the analysis-extras module so ICU is available in the same classloader as the other analysis components.
# This is required for the ICU folding filter to work.
COPY --chown=solr:solr solr/solrcloud/lib/solr10 /opt/solr/modules/analysis-extras/lib/
