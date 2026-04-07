// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "가계부",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/CoreOffice/CoreXLSX", from: "0.14.0"),
    ],
    targets: [
        .executableTarget(
            name: "Gakyebu",
            dependencies: [
                .product(name: "CoreXLSX", package: "CoreXLSX"),
            ],
            path: "Sources/Gakyebu",
            resources: [.process("Assets.xcassets")]
        )
    ]
)
