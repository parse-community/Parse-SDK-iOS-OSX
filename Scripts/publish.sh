#!/bin/sh -e
bundle install
bundle exec pod trunk push donotuse-testing.podspec
