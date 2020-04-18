#!/bin/sh -e
pod repo update
bundle exec pod trunk push Parse.podspec --verbose
