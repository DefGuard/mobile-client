// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "fido2_plugin",
    platforms: [
        // yubikit-swift's minimum
        .iOS("16.0")
    ],
    products: [
        .library(name: "fido2-plugin", targets: ["fido2_plugin"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/Yubico/yubikit-swift", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "fido2_plugin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "YubiKit", package: "yubikit-swift"),
            ],
            linkerSettings: [
                .linkedFramework("CoreNFC")
            ]
        )
    ]
)
