// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "UIComponents",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "UIComponents", targets: ["UIComponents"]),
    ],
    dependencies: [
        .package(path: "../DataModels"),
    ],
    targets: [
        .target(name: "UIComponents", dependencies: ["DataModels"]),
        .testTarget(name: "UIComponentsTests", dependencies: ["UIComponents"]),
    ]
)
