// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "QuickActionsPlugin",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "QuickActionsPlugin", type: .dynamic, targets: ["QuickActionsPlugin"]),
    ],
    dependencies: [
        .package(path: "../macos-status-bar/StatusBarKit"),
    ],
    targets: [
        .target(
            name: "QuickActionsPlugin",
            dependencies: [
                .product(name: "StatusBarKit", package: "StatusBarKit"),
            ]
        ),
    ]
)
