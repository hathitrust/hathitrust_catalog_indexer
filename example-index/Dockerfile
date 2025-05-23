# First, transform the MARC in JSON into Solr documents

FROM --platform=$BUILDPLATFORM jruby:9.4 AS traject

ENV BUNDLE_PATH=/gems
ENV redirect_file=/dev/null
ENV NO_DB=1

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential \
  git

RUN mkdir -p /gems

WORKDIR /app

RUN gem install bundler --version "~> 2.5.23"
COPY . /app
RUN bundle install

# outputs /app/debug.json
# records-to-index.json should be in ./example-index
RUN bundle exec bin/cictl index file --no-commit --writer=json example-index/records-to-index.jsonl

FROM --platform=$BUILDPLATFORM solr:8.11 AS indexer

ENV SOLR_PORT=9033

COPY --chown=solr:solr ./solr /var/solr/data
COPY --from=traject /app/debug.json /tmp/solrdocs.jsonl
COPY ./example-index/load_into_solr.sh /tmp

# The solr:8 Dockerfile includes
#
# VOLUME /var/solr
# https://github.com/docker-solr/docker-solr/blob/master/8.11/Dockerfile#L118
#
#
# Among other things, this means that anything we write to /var/solr/data
# during a RUN command will be lost:
# https://docs.docker.com/engine/reference/builder/#volume
# (Things copied with COPY do appear to persist.)
#
# Using multi-stage builds allows us to build the data, storing it in
# /tmp/biblio, and then copying from that temporary image into our final output
# image, in a way somewhat reminiscent of our current build/release process.

RUN mkdir /tmp/catalog-data && \
  ln -s /tmp/catalog-data /var/solr/data/catalog/data && \
  start-local-solr && \
  bash /tmp/load_into_solr.sh && \
  stop-local-solr

FROM solr:8.11

LABEL org.opencontainers.image.source=https://github.com/hathitrust/hathitrust_catalog_indexer

ENV SOLR_PORT=9033

COPY --chown=solr:solr ./solr /var/solr/data
COPY --from=indexer /tmp/catalog-data /var/solr/data/catalog/data

USER app