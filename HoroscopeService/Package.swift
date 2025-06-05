// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "HoroscopeService",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "HoroscopeService", targets: ["HoroscopeService"]),
    ],
    dependencies: [
        .package(path: "../CloudKitKit"),
        .package(path: "../AstroEngine"),
        .package(path: "../DataModels"),
    ],
    targets: [
        .target(name: "HoroscopeService",
                dependencies: ["CloudKitKit", "AstroEngine", "DataModels"]),
        .testTarget(name: "HoroscopeServiceTests", dependencies: ["HoroscopeService"]),
    ]
)
