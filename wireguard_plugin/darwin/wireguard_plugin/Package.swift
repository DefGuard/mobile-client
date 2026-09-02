// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "wireguard_plugin",
    platforms: [
        .iOS("15.0"),
        .macOS("11.0")
    ],
    products: [
        .library(name: "wireguard-plugin", targets: ["wireguard_plugin"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "wireguard_plugin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            linkerSettings: [
                // Mirrors `s.frameworks` and OTHER_LDFLAGS in wireguard_plugin.podspec.
                .linkedFramework("NetworkExtension"),
                .linkedFramework("Network")
            ]
        )
    ]
)
