// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ParseObjC",
    defaultLocalization: "en",
    platforms: [.iOS(.v12),
                .macOS(.v10_10),
                .tvOS(.v12),
                .watchOS(.v2)],
    products: [
        .library(name: "ParseObjC", targets: ["Parse"]),
        .library(name: "ParseFacebookUtilsiOS", targets: ["ParseFacebookUtilsiOS"]),
        .library(name: "ParseFacebookUtilsTvOS", targets: ["ParseFacebookUtilsTvOS"]),
        .library(name: "ParseTwitterUtils", targets: ["ParseTwitterUtils"]),
        .library(name: "ParseUI", targets: ["ParseUI"]),
        .library(name: "ParseLiveQuery", targets: ["ParseLiveQuery"])
    ],
    dependencies: [
        .package(url: "https://github.com/parse-community/Bolts-ObjC.git", from: "1.10.0"),
        .package(url: "https://github.com/BoltsFramework/Bolts-Swift.git", from: "1.5.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.4"),
        .package(url: "https://github.com/facebook/facebook-ios-sdk.git", from: "15.1.0")
    ],
    targets: [
        .target(
            name: "Parse",
            dependencies: [.product(name: "Bolts", package: "Bolts-ObjC")],
            path: "Parse/Parse",
            exclude: ["Resources/Parse-tvOS.Info.plist", "Resources/Parse-iOS.Info.plist", "Resources/Parse-OSX.Info.plist", "Resources/Parse-watchOS.Info.plist"],
            resources: [.process("Resources")],
            publicHeadersPath: "Source",
            cSettings: [.headerSearchPath("Internal/**")]),
        .target(
            name: "ParseFacebookUtils",
            dependencies: [
                "Parse",
                .product(name: "Bolts", package: "Bolts-ObjC"),
                .product(name: "FacebookCore", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS, .tvOS])),
                .product(name: "FacebookLogin", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS, .tvOS]))],
            path: "ParseFacebookUtils/ParseFacebookUtils",
            exclude: ["exclude", "Resources/Info-tvOS.plist", "Resources/Info-iOS.plist"],
            resources: [.process("Resources")],
            publicHeadersPath: "Source"),
        .target(name: "ParseFacebookUtilsiOS",
               dependencies: [
                "ParseFacebookUtils"
               ],
                path: "ParseFacebookUtilsiOS/ParseFacebookUtilsiOS",
                exclude: ["exclude", "Resources/Info-iOS.plist"],
                resources: [.process("Resources")],
                publicHeadersPath: "Source",
                cSettings: [.headerSearchPath("Internal/**")]),
        .target(name: "ParseFacebookUtilsTvOS",
               dependencies: [
                "ParseFacebookUtils",
                .product(name: "FacebookTV", package: "facebook-ios-sdk", condition: .when(platforms: [.tvOS]))
               ],
                path: "ParseFacebookUtilsTvOS/ParseFacebookUtilsTvOS",
                exclude: ["exclude", "Resources/Info-tvOS.plist"],
                resources: [.process("Resources")],
                publicHeadersPath: "Source",
                cSettings: [.headerSearchPath("Internal/**")]),
        .target(name: "ParseTwitterUtils",
               dependencies: [
                "Parse"
               ],
                path: "ParseTwitterUtils/ParseTwitterUtils",
                exclude: ["Resources/Info-iOS.plist"],
                resources: [.process("Resources")],
                publicHeadersPath: "Source",
                cSettings: [.headerSearchPath("Internal/**")]),
        .target(name: "ParseUI",
               dependencies: [
                "ParseFacebookUtilsiOS",
                "ParseTwitterUtils"
               ],
                path: "ParseUI/ParseUI",
                exclude: ["Resources/Info-iOS.plist"],
                resources: [.process("Resources")],
                publicHeadersPath: "Source",
                cSettings: [.headerSearchPath("Internal/**")]),
 	.target(name: "ParseLiveQuery",
               dependencies: [
                .product(name: "BoltsSwift", package: "Bolts-Swift"),
		"Starscream",
		"Parse"
               ],
                path: "ParseLiveQuery/ParseLiveQuery",
                resources: [.process("Resources")])
    ]
)
