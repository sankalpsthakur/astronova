// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "DataModels",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "DataModels", targets: ["DataModels"]),
    ],
    dependencies: [
        .package(path: "../CloudKitKit"),
    ],
    targets: [
        .target(name: "DataModels", dependencies: ["CloudKitKit"]),
        .testTarget(name: "DataModelsTests", dependencies: ["DataModels"]),
    ]
)
