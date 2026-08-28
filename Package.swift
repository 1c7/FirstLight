// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LightDose",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "LightDose",
            path: "Sources/LightDose",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AppKit"),
                .linkedFramework("CoreFoundation"),
            ]
        )
    ]
)
