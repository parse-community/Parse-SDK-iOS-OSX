ver=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Parse/Parse/Resources/Parse-iOS.Info.plist`
set -eo pipefail && bundle exec jazzy \
  --objc \
  --clean \
  --author "Parse Community" \
  --author_url http://parseplatform.org \
  --github_url https://github.com/parse-community/Parse-SDK-iOS-OSX \
  --root-url http://parseplatform.org/Parse-SDK-iOS-OSX/api/ \
  --module-version ${ver} \
  --theme fullwidth \
  --skip-undocumented \
  --module Parse \
  --umbrella-header Parse/Parse/Source/Parse.h \
  --framework-root Parse \
  --output docs/api
