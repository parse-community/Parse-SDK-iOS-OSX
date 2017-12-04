mkdir -p ./Bolts # Create a temporary bolts folder
cp -R Carthage/Checkouts/Bolts-ObjC/Bolts/**/*.h ./Bolts # Copy bolts

ver=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Parse/Resources/Parse-iOS.Info.plist`

jazzy \
  --objc \
  --author Parse \
  --author_url http://parseplatform.org \
  --github_url https://github.com/parse-community/Parse-SDK-iOS-OSX \
  --root-url http://parseplatform.org/Parse-SDK-iOS-OSX/api/ \
  --module-version ${ver} \
  --framework-root . \
  --umbrella-header Parse/Parse.h \
  --sdk=iphonesimulator \
  --exclude=./Bolts/* \
  --theme fullwidth \
  --skip-undocumented \
  --module Parse

rm -rf ./Bolts # cleanup temporary bolts