// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "qr_plugin",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "qr-plugin", targets: ["qr_plugin"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "qr_plugin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation")
            ]
        )
    ]
)
