#!/usr/bin/env bash

set -eo pipefail

bolts_headers_dir=""
for candidate in \
  "./.build/checkouts/Bolts-ObjC/Bolts" \
  "./.build/checkouts/Bolts/Bolts" \
  "./build/checkouts/Bolts-ObjC/Bolts" \
  "./SourcePackages/checkouts/Bolts-ObjC/Bolts"; do
  if [[ -d "$candidate" ]]; then
    bolts_headers_dir="$candidate"
    break
  fi
done

if [[ -z "$bolts_headers_dir" ]]; then
  echo "Unable to locate Bolts headers. Resolve SwiftPM dependencies first (for example, run 'swift package resolve')."
  exit 1
fi

mkdir -p ./Parse/Bolts
cp -R "$bolts_headers_dir"/. ./Parse/Bolts
trap 'rm -rf ./Parse/Bolts' EXIT

ver=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Parse/Parse/Resources/Parse-iOS.Info.plist`
bundle exec jazzy \
  --objc \
  --clean \
  --author "Parse Community" \
  --author_url http://parseplatform.org \
  --github_url https://github.com/parse-community/Parse-SDK-iOS-OSX \
  --root-url http://parseplatform.org/Parse-SDK-iOS-OSX/api/ \
  --module-version ${ver} \
  --theme fullwidth \
  --skip-undocumented \
  --exclude=./Bolts/* \
  --module Parse \
  --umbrella-header Parse/Parse/Source/Parse.h \
  --framework-root Parse \
  --output docs/api
