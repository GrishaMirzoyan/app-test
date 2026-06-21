// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LearningGateCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "LearningGateCore",
            targets: ["LearningGateCore"]
        )
    ],
    dependencies: [
        // Pure-Swift zip reader; works on both Apple platforms and Linux (for CI tests).
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0")
    ],
    targets: [
        // Thin system-library shim so we can link the OS's libsqlite3 on both
        // Apple platforms and Linux. Keeps the .apkg importer testable in CI.
        .systemLibrary(name: "CSQLite", path: "Sources/CSQLite"),
        .target(
            name: "LearningGateCore",
            dependencies: [
                "CSQLite",
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ]
        ),
        .testTarget(
            name: "LearningGateCoreTests",
            dependencies: ["LearningGateCore"],
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
