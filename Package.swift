// swift-tools-version:5.1

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
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-alpha.3"),
    ],
    targets: [
        .target(
            name: "VaporTypedRoutes",
            dependencies: ["Vapor"]),
        .testTarget(
            name: "VaporTypedRoutesTests",
            dependencies: ["VaporTypedRoutes", "Vapor", "XCTVapor"]),
    ]
)
