#!/bin/sh
#
# Copyright 2010-present Facebook.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script builds Bolts.framework as a dynamic lib

# This script is a workaround in order to build bolts specifically dynamically for Parse-iOS-Dynamic

# Process the build action, default to build
ACTION=$1
if [[ -z $ACTION ]]; then
	ACTION=build
fi

# Setup the environment
BOLTS_ROOT=./Vendor/Bolts-ObjC
BOLTS_SCRIPT=$BOLTS_ROOT/scripts

. ${BOLTS_SCRIPT:-$(dirname $0)}/common.sh

BUILDCONFIGURATION=Release
BOLTS_BUILD=$PARSE_DIR/build
BOLTS_IOS_BINARY=$PARSE_DIR/build/${BUILDCONFIGURATION}-universal/Bolts.framework/Bolts

XCCONFIG_FILE=$PARSE_DIR/Configurations/Bolts-iOS-Dynamic.xcconfig

echo $XCODEBUILD


function xcode_build_target() {
  echo "Compiling for platform: ${1}."
  "$XCODEBUILD" \
  -project $BOLTS_ROOT/Bolts.xcodeproj\
  -scheme "${3}" \
  -sdk $1 \
  -configuration "${2}" \
  -xcconfig $XCCONFIG_FILE \
  SYMROOT="$PARSE_DIR/build/" \
  CURRENT_PROJECT_VERSION="$BOLTS_VERSION_FULL" \
  $ACTION \
  || die "Xcode build failed for platform: ${1}."
}

FRAMEWORK_NAME=Bolts

xcode_build_target "iphonesimulator" "${BUILDCONFIGURATION}" "Bolts-iOS"
xcode_build_target "iphoneos" "${BUILDCONFIGURATION}" "Bolts-iOS"

if [ "$ACTION" == "clean" ]; then
	#statements
	echo "EXIT!"
	exit 0
fi

mkdir -p "$(dirname "$BOLTS_IOS_BINARY")"

cp -av \
"$BOLTS_BUILD/${BUILDCONFIGURATION}-iphoneos/Bolts.framework" \
"$BOLTS_BUILD/${BUILDCONFIGURATION}-universal"
rm "$BOLTS_BUILD/${BUILDCONFIGURATION}-universal/Bolts.framework/Bolts"

# Combine iOS/Simulator binaries into a single universal binary.
"$LIPO" \
-create \
"$BOLTS_BUILD/${BUILDCONFIGURATION}-iphonesimulator/Bolts.framework/Bolts" \
"$BOLTS_BUILD/${BUILDCONFIGURATION}-iphoneos/Bolts.framework/Bolts" \
-output "$BOLTS_IOS_BINARY" \
|| die "lipo failed - could not create universal static library"

cp -av $PARSE_DIR/build/${BUILDCONFIGURATION}-universal/Bolts.framework \
  "$BOLTS_BUILD"

rm -rf $PARSE_DIR/build/${BUILDCONFIGURATION}-universal
rm -rf $PARSE_DIR/build/${BUILDCONFIGURATION}-iphonesimulator
