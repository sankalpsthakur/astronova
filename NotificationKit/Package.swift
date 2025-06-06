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
        .package(path: "../HoroscopeService"),
    ],
    targets: [
        .target(name: "NotificationKit", dependencies: ["CloudKitKit", "DataModels", "HoroscopeService"]),
        .testTarget(name: "NotificationKitTests", dependencies: ["NotificationKit"]),
    ]
)
