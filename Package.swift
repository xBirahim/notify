// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "notifyctl",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "notifyctl", targets: ["notifyctl"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "notifyctl",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "notifyctlTests",
            dependencies: ["notifyctl"]
        )
    ],
    swiftLanguageModes: [.v6]
)
