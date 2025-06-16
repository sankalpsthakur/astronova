// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AstronovaNetworking",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(
            name: "AstronovaNetworking",
            targets: ["AstronovaNetworking"]
        ),
    ],
    dependencies: [
        // No external dependencies required
    ],
    targets: [
        .target(
            name: "AstronovaNetworking",
            dependencies: []
        ),
        .testTarget(
            name: "AstronovaNetworkingTests",
            dependencies: ["AstronovaNetworking"]
        ),
    ]
)