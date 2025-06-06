// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "astronova",
    platforms: [.iOS(.v15)],
    products: [
        // Expose the Astronova application target as a library for previews/tests.
        .library(
            name: "astronova",
            targets: ["astronova"]
        ),
    ],
    dependencies: [
        // No external dependencies required
    ],
    targets: [
        .target(
            name: "astronova",
            dependencies: [
                // No external dependencies required
            ]
        ),
        .testTarget(
            name: "astronovaTests",
            dependencies: ["astronova"]
        ),
    ]
)
