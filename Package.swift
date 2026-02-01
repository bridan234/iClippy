// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iClippy",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "iClippy",
            targets: ["iClippy"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Clipy/Magnet.git", from: "3.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "iClippy",
            dependencies: [
                "Magnet"
            ],
            path: "Sources"
        )
    ]
)
