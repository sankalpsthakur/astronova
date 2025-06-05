// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AstroEngine",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "AstroEngine", targets: ["AstroEngine"]),
    ],
    dependencies: [
        .package(path: "../DataModels"),
    ],
    targets: [
        .target(name: "AstroEngine", dependencies: ["DataModels"]),
        .testTarget(name: "AstroEngineTests", dependencies: ["AstroEngine"]),
    ]
)
