// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AuthKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "AuthKit", targets: ["AuthKit"]),
    ],
    dependencies: [
        .package(path: "../CloudKitKit"),
        .package(path: "../DataModels"),
    ],
    targets: [
        .target(name: "AuthKit", dependencies: ["CloudKitKit", "DataModels"]),
        .testTarget(name: "AuthKitTests", dependencies: ["AuthKit"]),
    ]
)
