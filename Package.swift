// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Networking",
            targets: ["Networking"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Networking")
    ]
)
