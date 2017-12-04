#!/bin/sh -e
gem install bundler
bundle install
bundle exec pod trunk push donotuse-testing.podspec
