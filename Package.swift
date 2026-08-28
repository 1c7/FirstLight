// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FirstLight",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "FirstLight",
            path: "Sources/FirstLight",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AppKit"),
                .linkedFramework("CoreFoundation"),
            ]
        )
    ]
)
