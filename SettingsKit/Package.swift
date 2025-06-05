// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "SettingsKit",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(name: "SettingsKit", targets: ["SettingsKit"]),
    ],
    dependencies: [
        .package(path: "../CloudKitKit"),
        .package(path: "../DataModels"),
    ],
    targets: [
        .target(name: "SettingsKit", dependencies: ["CloudKitKit", "DataModels"]),
        .testTarget(name: "SettingsKitTests", dependencies: ["SettingsKit"]),
    ]
)
