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
        .package(path: "../DataModels"),
    ],
    targets: [
        .target(name: "ChartVisualization", dependencies: [
            "SwissEphemeris",
            "AstroEngine", 
            "DataModels"
        ]),
        .testTarget(name: "ChartVisualizationTests", dependencies: ["ChartVisualization"]),
    ]
)