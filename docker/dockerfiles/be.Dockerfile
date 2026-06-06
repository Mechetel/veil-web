ARG RUBY_VERSION=3.4.9
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

USER root

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client \
    build-essential git libpq-dev libyaml-dev pkg-config imagemagick nano && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV APP_USER=app

RUN useradd -m -d /home/$APP_USER $APP_USER
RUN mkdir /app && chown -R $APP_USER:$APP_USER /app

WORKDIR /app

USER $APP_USER
