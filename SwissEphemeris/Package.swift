// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "SwissEphemeris",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "SwissEphemeris", targets: ["SwissEphemeris"]),
    ],
    targets: [
        .target(name: "SwissEphemeris", dependencies: []),
        .testTarget(name: "SwissEphemerisTests", dependencies: ["SwissEphemeris"]),
    ]
)
