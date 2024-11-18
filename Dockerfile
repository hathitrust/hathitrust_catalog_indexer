FROM jruby:9.4-jdk17 AS base
ARG UNAME=app
ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential \
  git

WORKDIR /app

# USER $UNAME
ENV BUNDLE_PATH /gems
RUN gem install bundler

FROM base AS development

FROM base AS production

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -d /app -u $UID -g $GID -o -s /bin/bash $UNAME
RUN mkdir -p /gems && chown $UID:$GID /gems
USER $UNAME
COPY --chown=$UID:$GID Gemfile* /app
WORKDIR /app
ENV BUNDLE_PATH /gems
RUN bundle install
COPY --chown=$UID:$GID . /app

LABEL org.opencontainers.image.source="https://github.com/hathitrust/hathitrust_catalog_indexer"
