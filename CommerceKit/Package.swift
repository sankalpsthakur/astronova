// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "CommerceKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "CommerceKit", targets: ["CommerceKit"]),
    ],
    dependencies: [
        .package(path: "../CloudKitKit"),
        .package(path: "../DataModels"),
    ],
    targets: [
        .target(name: "CommerceKit", dependencies: ["CloudKitKit", "DataModels"]),
        .testTarget(name: "CommerceKitTests", dependencies: ["CommerceKit"]),
    ]
)
