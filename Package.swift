// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "VaporTypedRoutes",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "VaporTypedRoutes",
            targets: ["VaporTypedRoutes"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.50.0")),
    ],
    targets: [
        .target(
            name: "VaporTypedRoutes",
            dependencies: [.product(name: "Vapor", package: "vapor")]),
        .testTarget(
            name: "VaporTypedRoutesTests",
            dependencies: [
                "VaporTypedRoutes",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "XCTVapor", package: "vapor")
        ]),
    ]
)
