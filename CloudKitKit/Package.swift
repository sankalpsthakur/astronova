// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "CloudKitKit",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(name: "CloudKitKit", targets: ["CloudKitKit"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "CloudKitKit", dependencies: []),
        .testTarget(name: "CloudKitKitTests", dependencies: ["CloudKitKit"]),
    ]
)
