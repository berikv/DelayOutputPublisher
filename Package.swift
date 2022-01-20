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
        .package(name: "VirtualTimeScheduler", path: "../VirtualTimeScheduler")
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
