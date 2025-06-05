// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "NotificationKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "NotificationKit", targets: ["NotificationKit"]),
    ],
    dependencies: [
        .package(path: "../CloudKitKit"),
        .package(path: "../DataModels"),
    ],
    targets: [
        .target(name: "NotificationKit", dependencies: ["CloudKitKit", "DataModels"]),
        .testTarget(name: "NotificationKitTests", dependencies: ["NotificationKit"]),
    ]
)
