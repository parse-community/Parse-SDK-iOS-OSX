mkdir -p ./Bolts # Create a temporary bolts folder
cp -R Carthage/Checkouts/Bolts-ObjC/Bolts/**/*.h ./Bolts # Copy bolts

ver=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Parse/Resources/Parse-iOS.Info.plist`
jazzy \
  --objc \
  --clean \
  --author "Parse Community" \
  --author_url http://parseplatform.org \
  --github_url https://github.com/parse-community/Parse-SDK-iOS-OSX \
  --root-url http://parseplatform.org/Parse-SDK-iOS-OSX/api/ \
  --module-version ${ver} \
  --xcodebuild-arguments --objc,Parse/Parse.h,--,-x,objective-c,-isysroot,$(xcrun --show-sdk-path --sdk iphonesimulator),-I,$(pwd) \
  --theme fullwidth \
  --skip-undocumented \
  --exclude=./Bolts/* \
  --module Parse \
  --output docs/api

rm -rf ./Bolts # cleanup temporary bolts
