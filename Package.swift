// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iClippy",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "iClippy",
            targets: ["iClippy"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Clipy/Magnet.git", from: "3.4.0")
    ],
    targets: [
        .executableTarget(
            name: "iClippy",
            dependencies: ["Magnet"],
            path: "Sources",
            resources: [
                .process("Info.plist")
            ]
        )
    ]
)
