// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ParseObjC",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15),
        .tvOS(.v12),
        .watchOS(.v2)
    ],
    products: [
        .library(name: "ParseObjC", targets: ["ParseCore"]),
        .library(name: "ParseFacebookUtils", targets: ["ParseFacebookUtils"]),
        .library(name: "ParseFacebookUtilsiOS", targets: ["ParseFacebookUtilsiOS"]),
        .library(name: "ParseTwitterUtils", targets: ["ParseTwitterUtils"]),
        .library(name: "ParseUI", targets: ["ParseUI"]),
        .library(name: "ParseLiveQuery", targets: ["ParseLiveQuery"])
    ],
    dependencies: [
        .package(url: "https://github.com/parse-community/Bolts-ObjC.git", from: "1.10.0"),
        .package(url: "https://github.com/BoltsFramework/Bolts-Swift.git", from: "1.5.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.6"),
        .package(url: "https://github.com/facebook/facebook-ios-sdk.git", from: "17.0.0"),
        .package(name: "OCMock", url: "https://github.com/erikdoe/ocmock.git", .revision("67bb9602f0a7541f24dc2d6d0d7389ca3e4c2c89"))
    ],
    targets: [
        .target(
            name: "ParseCore",
            dependencies: [.product(name: "Bolts", package: "Bolts-ObjC")],
            path: "Parse/Parse",
            exclude: ["Resources/Parse-tvOS.Info.plist", "Resources/Parse-iOS.Info.plist", "Resources/Parse-OSX.Info.plist", "Resources/Parse-watchOS.Info.plist"],
            resources: [.process("Resources")],
            publicHeadersPath: "Source",
            cSettings: [.headerSearchPath("Internal/**")]
        ),
        .target(
            name: "ParseFacebookUtils",
            dependencies: [
                "ParseCore",
                .product(name: "Bolts", package: "Bolts-ObjC"),
                .product(name: "FacebookCore", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS, .tvOS])),
                .product(name: "FacebookLogin", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS, .tvOS]))],
            path: "ParseFacebookUtils/ParseFacebookUtils",
            exclude: ["Resources/Info-tvOS.plist", "Resources/Info-iOS.plist"],
            resources: [.process("Resources")],
            publicHeadersPath: "Source"
        ),
        .target(
            name: "ParseFacebookUtilsiOS",
            dependencies: [
                "ParseFacebookUtils"
            ],
            path: "ParseFacebookUtilsiOS/ParseFacebookUtilsiOS",
            exclude: ["Resources/Info-iOS.plist"],
            resources: [.process("Resources")],
            publicHeadersPath: "Source",
            cSettings: [.headerSearchPath("Internal/**")]
        ),
        .target(
            name: "ParseTwitterUtils",
            dependencies: [
                "ParseCore"
            ],
            path: "ParseTwitterUtils/ParseTwitterUtils",
            exclude: ["Resources/Info-iOS.plist"],
            resources: [.process("Resources")],
            publicHeadersPath: "Source",
            cSettings: [.headerSearchPath("Internal/**")]
        ),
        .target(
            name: "ParseUI",
            dependencies: [
                "ParseFacebookUtilsiOS",
                "ParseTwitterUtils"
            ],
            path: "ParseUI/ParseUI",
            exclude: ["Resources/Info-iOS.plist"],
            resources: [.process("Resources")],
            publicHeadersPath: "Source",
            cSettings: [.headerSearchPath("Internal/**")]
        ),
        .target(
            name: "ParseLiveQuery",
            dependencies: [
                .product(name: "BoltsSwift", package: "Bolts-Swift"),
                "Starscream",
                "ParseCore"
            ],
            path: "ParseLiveQuery/ParseLiveQuery",
            exclude: ["Resources/Info.plist"],
            resources: [.process("Resources")]
        )
    ]
)
