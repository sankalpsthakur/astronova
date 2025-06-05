// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AppCore",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "AppCore", targets: ["AppCore"]),
    ],
    dependencies: [
        .package(path: "../AuthKit"),
        .package(path: "../HoroscopeService"),
        .package(path: "../NotificationKit"),
        .package(path: "../CommerceKit"),
        .package(path: "../UIComponents"),
        .package(path: "../SettingsKit"),
    ],
    targets: [
        .target(name: "AppCore", dependencies: [
            "AuthKit",
            "HoroscopeService",
            "NotificationKit",
            "CommerceKit",
            "UIComponents",
            "SettingsKit",
        ]),
        .testTarget(name: "AppCoreTests", dependencies: ["AppCore"]),
    ]
)
