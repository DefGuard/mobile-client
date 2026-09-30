// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "fido2_plugin",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "fido2-plugin", targets: ["fido2_plugin"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "fido2_plugin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
