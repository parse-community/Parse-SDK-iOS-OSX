#!/bin/sh -e
pod repo update
EXPANDED_CODE_SIGN_IDENTITY="-" EXPANDED_CODE_SIGN_IDENTITY_NAME="-" bundle exec pod trunk push Parse.podspec --allow-warnings
