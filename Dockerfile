FROM jruby:9.4-jdk17
ARG UNAME=app
ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  build-essential \
  git \
  netbase \
  nano

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

# COPY --chown=${UID}:${GID} Gemfile* /app/
WORKDIR /app

# USER $UNAME
ENV BUNDLE_PATH /gems
RUN gem install bundler
