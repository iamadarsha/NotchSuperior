// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NSExtensionSDK",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "NSExtensionSDK",
            targets: ["NSExtensionSDK"]),
    ],
    targets: [
        .target(
            name: "NSExtensionSDK",
            dependencies: [])
    ]
)
