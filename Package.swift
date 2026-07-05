// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Tahoe 窗口外观切换器",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "Tahoe 窗口外观切换器", targets: ["AppearanceSwitcher"])
    ],
    targets: [
        .executableTarget(
            name: "AppearanceSwitcher"
        )
    ]
)
