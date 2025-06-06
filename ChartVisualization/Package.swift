// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "ChartVisualization",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ChartVisualization", targets: ["ChartVisualization"]),
    ],
    dependencies: [
        .package(path: "../SwissEphemeris"),
        .package(path: "../AstroEngine"),
    ],
    targets: [
        .target(name: "ChartVisualization", dependencies: [
            "SwissEphemeris",
            "AstroEngine"
        ]),
        .testTarget(name: "ChartVisualizationTests", dependencies: ["ChartVisualization"]),
    ]
)