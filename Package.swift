// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PipecatClientIOSDaily",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "PipecatClientIOSDaily",
            targets: ["PipecatClientIOSDaily"]),
    ],
    dependencies: [
        // Local dependency
        //.package(path: "../pipecat-client-ios"),
        .package(url: "https://github.com/pipecat-ai/pipecat-client-ios.git", from: "0.3.2"),
        .package(url: "https://github.com/daily-co/daily-client-ios.git", from: "0.23.0")
    ],
    targets: [
        .target(
            name: "PipecatClientIOSDaily",
            dependencies: [
                .product(name: "PipecatClientIOS", package: "pipecat-client-ios"),
                .product(name: "Daily", package: "daily-client-ios")
            ]),
        .testTarget(
            name: "PipecatClientIOSDailyTests",
            dependencies: ["PipecatClientIOSDaily"]),
    ]
)
