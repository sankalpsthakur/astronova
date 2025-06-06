// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "ChatService",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ChatService", targets: ["ChatService"]),
    ],
    dependencies: [
        .package(path: "../DataModels"),
        .package(path: "../AuthKit"),
        .package(path: "../CloudKitKit"),
        .package(path: "../ChartVisualization"),
    ],
    targets: [
        .target(name: "ChatService", dependencies: ["DataModels", "AuthKit", "CloudKitKit", "ChartVisualization"]),
        .testTarget(name: "ChatServiceTests", dependencies: ["ChatService"]),
    ]
)