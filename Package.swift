// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "가계부",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/CoreOffice/CoreXLSX", from: "0.14.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Gakyebu",
            dependencies: [
                .product(name: "CoreXLSX", package: "CoreXLSX"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/Gakyebu",
            resources: [.process("Assets.xcassets")]
        )
    ]
)
