#!/usr/bin/env bash

rm -f consul-ruby-client-*.gem && \
  gem build consul-ruby-client.gemspec && \
  gem install consul-ruby-client-*.gem