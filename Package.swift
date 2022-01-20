// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parse",
    platforms: [.iOS(.v9), .macOS(.v10_10), .tvOS(.v9), .watchOS(.v6)],
    products: [
        .library(
            name: "Parse",
            targets: ["Parse"]),
    ],
    dependencies: [
        .package(name: "Bolts", url: "https://github.com/mman/Bolts-ObjC.git", branch: "spm"),
        .package(name: "OCMock", url: "https://github.com/erikdoe/ocmock.git", branch: "master")
    ],
    targets: [
        .target(
            name: "Parse",
            dependencies: ["Bolts"],
            sources: ["src"],
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("include"), .headerSearchPath("src"), .headerSearchPath("src/internal")]),
        .testTarget(
            name: "ParseTests",
            dependencies: ["Parse", "Bolts", "OCMock"],
            cSettings: [.headerSearchPath("../../Sources/Parse/src/"), .headerSearchPath("../../Sources/Parse/src/internal")]),
    ]
)
