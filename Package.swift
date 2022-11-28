// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parse-SDK-iOS-OSX",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v5)
    ],
    products: [
        .library(
            name: "Parse",
            type: .dynamic,
            targets: ["Parse-iOS"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        // .package(url: "https://github.com/BoltsFramework/Bolts-Swift", branch: "main")
        .package(url: "https://github.com/mman/Bolts-ObjC.git", branch: "spm"),
        .package(url: "https://github.com/erikdoe/ocmock.git", branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        // .target(
        //     name: "Bolt-iOS",
        //     dependencies: [
        //         // .product(name: "BoltsSwift", package: "Bolts-Swift")
        //     ],
        //     path: "Carthage/Checkouts/Bolts-ObjC/Bolts",
        //     publicHeadersPath: ".",
        //     cSettings: [
        //         .headerSearchPath("Internal"),
        //     ]
        // ),
        .target(
            name: "Parse-iOS",
            dependencies: [
                .product(name: "Bolts", package: "Bolts-ObjC"),
                .product(name: "OCMock", package: "ocmock")
            ],
            path: "Parse/Parse",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Internal"),
                .headerSearchPath("Internal/Object"),
                .headerSearchPath("Internal/Object/Controller/OfflineController"),
                .headerSearchPath("Internal/Object/LocalIdStore"),
                .headerSearchPath("Internal/Object/EstimatedData"),
                .headerSearchPath("Internal/Object/BatchController"),
                .headerSearchPath("Internal/Object/PinningStore"),
                .headerSearchPath("Internal/Object/OperationSet"),
                .headerSearchPath("Internal/Object/State"),
                .headerSearchPath("Internal/Object/Constants"),
                .headerSearchPath("Internal/Object/Subclassing"),
                .headerSearchPath("Internal/Object/Utilities"),
                .headerSearchPath("Internal/Object/Coder/File"),
                .headerSearchPath("Internal/Object/Controller"),
                .headerSearchPath("Internal/Object/FilePersistence"),
                .headerSearchPath("Internal/Object/CurrentController"),
                .headerSearchPath("Internal/User"),
                .headerSearchPath("Internal/User/AuthenticationProviders/Providers/Anonymous"),
                .headerSearchPath("Internal/User/AuthenticationProviders/Controller"),
                .headerSearchPath("Internal/User/Constants"),
                .headerSearchPath("Internal/User/Controller"),
                .headerSearchPath("Internal/User/State"),
                .headerSearchPath("Internal/User/Coder/File"),
                .headerSearchPath("Internal/User/CurrentUserController"),
                .headerSearchPath("Internal/Product"),
                .headerSearchPath("Internal/Product/ProductsRequestHandler"),
                .headerSearchPath("Internal/LocalDataStore"),
                .headerSearchPath("Internal/LocalDataStore/SQLite"),
                .headerSearchPath("Internal/LocalDataStore/OfflineQueryLogic"),
                .headerSearchPath("Internal/LocalDataStore/OfflineStore"),
                .headerSearchPath("Internal/LocalDataStore/Pin"),
                .headerSearchPath("Internal/Commands"),
                .headerSearchPath("Internal/Commands/CommandRunner"),
                .headerSearchPath("Internal/Commands/CommandRunner/URLRequestConstructor"),
                .headerSearchPath("Internal/Commands/CommandRunner/URLSession"),
                .headerSearchPath("Internal/Commands/CommandRunner/URLSession/Session"),
                .headerSearchPath("Internal/Commands/CommandRunner/URLSession/Session/TaskDelegate"),
                .headerSearchPath("Internal/Relation"),
                .headerSearchPath("Internal/Relation/State"),
                .headerSearchPath("Internal/Analytics"),
                .headerSearchPath("Internal/Analytics/Utilities"),
                .headerSearchPath("Internal/Analytics/Controller"),
                .headerSearchPath("Internal/FieldOperation"),
                .headerSearchPath("Internal/Installation/Constants"),
                .headerSearchPath("Internal/Installation/InstallationIdentifierStore"),
                .headerSearchPath("Internal/Installation/CurrentInstallationController"),
                .headerSearchPath("Internal/Query"),
                .headerSearchPath("Internal/Query/Controller"),
                .headerSearchPath("Internal/Query/State"),
                .headerSearchPath("Internal/Query/Utilities"),
                .headerSearchPath("Internal/KeyValueCache"),
                .headerSearchPath("Internal/MultiProcessLock"),
                .headerSearchPath("Internal/ACL"),
                .headerSearchPath("Internal/ACL/State"),
                .headerSearchPath("Internal/ACL/DefaultACLController"),
                .headerSearchPath("Internal/Purchase/PaymentTransactionObserver"),
                .headerSearchPath("Internal/Purchase/Controller"),
                .headerSearchPath("Internal/Session/Controller"),
                .headerSearchPath("Internal/Session/Utilities"),
                .headerSearchPath("Internal/File"),
                .headerSearchPath("Internal/File/State"),
                .headerSearchPath("Internal/File/Controller"),
                .headerSearchPath("Internal/File/FileDataStream"),
                .headerSearchPath("Internal/Persistence"),
                .headerSearchPath("Internal/Persistence/Group"),
                .headerSearchPath("Internal/Installation"),
                .headerSearchPath("Internal/Installation/Controller"),
                .headerSearchPath("Internal/PropertyInfo"),
                .headerSearchPath("Internal/CloudCode"),
                .headerSearchPath("Internal/Config"),
                .headerSearchPath("Internal/Config/Controller"),
                .headerSearchPath("Internal/Push"),
                .headerSearchPath("Internal/Push/State"),
                .headerSearchPath("Internal/Push/Utilites"),
                .headerSearchPath("Internal/Push/Manager"),
                .headerSearchPath("Internal/Push/Controller"),
                .headerSearchPath("Internal/Push/ChannelsController"),
                .headerSearchPath("Internal/ThreadSafety"),
                .headerSearchPath("Internal/HTTPRequest/RequestConstructor"),
                .headerSearchPath("Internal/HTTPRequest")
            ]
        )
        
        // .executableTarget(
        //     name: "Parse-SDK-iOS-OSX",
        //     dependencies: []),
        // .testTarget(
        //     name: "Parse-SDK-iOS-OSXTests",
        //     dependencies: ["Parse-SDK-iOS-OSX"]),
    ]
)
