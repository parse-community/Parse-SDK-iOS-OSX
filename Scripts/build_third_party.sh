#!/bin/bash
#
# Copyright (c) 2015-present, Parse, LLC.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

set -e

if [[ $ACTION == "clean" ]]; then
  exit 0
fi

if [[ $1 == "" || $2 == "" ]]; then
  echo "Use this script to build a third party framework for iOS/OSX."
  echo "It is intended to support building Bolts.framework and FacebookSDK.framework"
  echo "Usage: 'build_third_party.sh <framework_path> <build_script_path>"
  exit 1
fi

SOURCE_DIR=$(cd "$(dirname "$0")"; pwd)
FRAMEWORK_DIR=$(cd "$1"; pwd)
BUILD_DIR="$1"/build
SCRIPT_PATH=$2

if [ ! -d "$FRAMEWORK_DIR" ]; then
  echo "Framework path supplied doesn't exist. Please double check it and try again."
  exit 1
fi

NUM_CHANGES=$(git status --porcelain "$FRAMEWORK_DIR" | wc -l)
HAS_CHANGES=$([[ $NUM_CHANGES -gt 0 ]] && echo 1 || echo 0)

BUILD_REVISION_PATH=$2/build_revision
LAST_REVISION=$(git log -n 1 --format=%h .)

if [[ $HAS_CHANGES == 0 ]]; then
  echo "No local changes inside $FRAMEWORK_DIR."

  LAST_BUILD_REVISION=$([ -e "$BUILD_REVISION_PATH" ] && cat "$BUILD_REVISION_PATH" || echo 0)

  if [[ $LAST_REVISION != $LAST_BUILD_REVISION ]]; then
    echo "Found new revision for $FRAMEWORK_DIR. Rebuilding..."
    HAS_CHANGES=1
  fi
fi

if [[ $HAS_CHANGES == 1 ]]; then
  SCRIPTS_DIR=$(dirname "$SCRIPT_PATH")
  SCRIPT_FILE=$(basename "$SCRIPT_PATH")

  cd $SCRIPTS_DIR
  eval "XCTOOL=xcodebuild ./$SCRIPT_FILE"
  BUILD_RESULT=$?

  if [[ $BUILD_RESULT == 0 ]]; then
    cd "$BUILD_DIR"
    echo $LAST_REVISION > build_revision
  fi
fi
