// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BenimSehrim",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "BenimSehrim", targets: ["BenimSehrim"])
    ],
    dependencies: [
        // No external dependencies - using native frameworks
    ],
    targets: [
        .target(
            name: "BenimSehrim",
            dependencies: []
        )
    ]
)
