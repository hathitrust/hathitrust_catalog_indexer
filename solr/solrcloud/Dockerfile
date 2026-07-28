FROM solr:9.10.1

ENV SOLR_PORT=9033

# analysis-extras is needed for the ICU folding filter, scripting is needed for the JavaScript update processor.
ENV SOLR_MODULES=analysis-extras,scripting

# Load JARs inside the analysis-extras module so ICU is available in the same classloader as the other analysis components.
# This is required for the ICU folding filter to work.
USER root
RUN curl -fL \
    -o /opt/solr/modules/analysis-extras/lib/umich-solr-extensions.jar \
    https://github.com/mlibrary/umich-lib-solr-extensions/releases/download/v1.1/umich-solr-extensions.jar \
    && chown solr:solr /opt/solr/modules/analysis-extras/lib/umich-solr-extensions.jar
USER solr
