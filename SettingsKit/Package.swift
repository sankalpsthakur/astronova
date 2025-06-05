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
    ],
    targets: [
        .target(name: "SettingsKit", dependencies: ["CloudKitKit"]),
        .testTarget(name: "SettingsKitTests", dependencies: ["SettingsKit"]),
    ]
)
