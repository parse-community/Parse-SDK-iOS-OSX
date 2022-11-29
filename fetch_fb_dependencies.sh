if [ ! -d Carthage/Build ]; then
    mkdir Carthage/Build
fi

cd Carthage/Build

if [ ! -d "FBSDKCoreKit.xcframework" ] || [ ! -d "FBSDKLoginKit.xcframework" ] || [ ! -d "FBSDKCoreKit_Basics.xcframework" ] || [ ! -d "FBAEMKit.xcframework" ] || [ ! -d "FBSDKTVOSKit.xcframework" ]; then
    ARCHIVE_NAME=FBSDK.zip

    ARCHIVE_URL="https://github.com/facebook/facebook-ios-sdk/releases/download/v15.1.0/FacebookSDK-Static_XCFramework.zip"
    curl -Lk $ARCHIVE_URL -o $ARCHIVE_NAME

    unzip $ARCHIVE_NAME -d fbsdk
    rm -rf FBSDKCoreKit.xcframework
    rm -rf FBSDKLoginKit.xcframework
    rm -rf FBSDKCoreKit_Basics.xcframework
    rm -rf FBAEMKit.xcframework
    rm -rf FBSDKTVOSKit.xcframework

    mv fbsdk/XCFrameworks/FBSDKCoreKit.xcframework .
    mv fbsdk/XCFrameworks/FBSDKLoginKit.xcframework .
    mv fbsdk/XCFrameworks/FBSDKCoreKit_Basics.xcframework .
    mv fbsdk/XCFrameworks/FBAEMKit.xcframework .
    mv fbsdk/XCFrameworks/FBSDKTVOSKit.xcframework .

    rm $ARCHIVE_NAME
    rm -r fbsdk
fi
