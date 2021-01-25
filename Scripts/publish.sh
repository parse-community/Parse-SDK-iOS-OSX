#!/bin/sh -e
gem install bundler
bundle install
bundle exec pod trunk push Parse.podspec --verbose
