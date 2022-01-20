// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DelayOutputPublisher",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "DelayOutputPublisher",
            targets: ["DelayOutputPublisher"]),
    ],
    dependencies: [
        .package(name: "VirtualTimeScheduler", url: "https://github.com/berikv/VirtualTimeScheduler", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "DelayOutputPublisher",
            dependencies: []),
        .testTarget(
            name: "DelayOutputPublisherTests",
            dependencies: [
                "DelayOutputPublisher",
                "VirtualTimeScheduler"
            ]),
    ]
)
