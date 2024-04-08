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
        .library(name: "ParseUI", targets: ["ParseUI"]),
        .library(name: "ParseLiveQuery", targets: ["ParseLiveQuery"])
    ],
    dependencies: [
        .package(url: "https://github.com/parse-community/Bolts-ObjC.git", from: "1.10.0"),
        .package(url: "https://github.com/BoltsFramework/Bolts-Swift.git", from: "1.5.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.6"),
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
            name: "ParseUI",
            dependencies: [
                "ParseCore"
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
