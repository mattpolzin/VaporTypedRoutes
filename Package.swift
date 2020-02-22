// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "VaporTypedRoutes",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .library(
            name: "VaporTypedRoutes",
            targets: ["VaporTypedRoutes"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.3.24"),
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
