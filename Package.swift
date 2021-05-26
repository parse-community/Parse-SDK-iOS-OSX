// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parse",
    defaultLocalization: "en",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Parse",
            targets: ["Parse"]),
        // .library(
        //     name: "ParseFacebookUtils",
        //     targets: ["ParseFacebookUtils"]),
        // .library(
        //     name: "ParseTwitterUtils",
        //     targets: ["ParseTwitterUtils"]),

    ],
    dependencies: [
        .package(name: "Bolts", url: "https://github.com/drdaz/Bolts-ObjC", .branch("master"))
//        .package(name: "Bolts",
//                 url: "https://github.com/drdaz/Bolts-ObjC",
//                 .revision("df0c47add16f6cb7e81fd28aa59518c607a9dd4e"))
//            .package(name: "Bolts", path: "/Users/drdaz/Documents/Development/Others/Bolts-ObjC")
    ],
    targets: [
        .target(
            name: "Parse",
            dependencies: [.product(name: "Bolts", package: "Bolts")],
            path: "Parse/Source",
            exclude: ["Info.plist"],
            publicHeadersPath: "Public"
        )
    ]
)
