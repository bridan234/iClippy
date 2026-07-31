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
        .package(url: "https://github.com/Clipy/Magnet.git", from: "3.5.0")
    ],
    targets: [
        .executableTarget(
            name: "iClippy",
            dependencies: ["Magnet"],
            path: "Sources",
            // Info.plist is the app bundle's own plist, copied in by make-app.sh.
            // SwiftPM refuses it as a top-level resource, so keep it out of the target.
            exclude: ["Info.plist"]
        )
    ]
)
