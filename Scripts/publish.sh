#!/bin/sh -e
gem install bundler
bundle install
pod repo update
bundle exec pod trunk push Parse.podspec --verbose
