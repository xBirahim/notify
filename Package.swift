// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "notify",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "notify", targets: ["notify"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "notify",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "notifyTests",
            dependencies: ["notify"]
        )
    ],
    swiftLanguageModes: [.v6]
)
