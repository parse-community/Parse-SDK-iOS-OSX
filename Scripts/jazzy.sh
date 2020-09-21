mkdir -p ./Parse/Bolts # Create a temporary bolts folder
cp -R Carthage/Checkouts/Bolts-ObjC/Bolts/**/*.h ./Parse/Bolts # Copy bolts

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
  --umbrella-header Parse/Parse/Parse.h \
  --framework-root Parse \
  --output docs/api

rm -rf ./Parse/Bolts # cleanup temporary bolts
