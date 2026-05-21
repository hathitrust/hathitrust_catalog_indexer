FROM solr:10.0.0

# Load JARs inside the analysis-extras module so ICU is available in the same classloader as the other analysis components.
# This is required for the ICU folding filter to work.
COPY --chown=solr:solr lib/solr10 /opt/solr/modules/analysis-extras/lib/
