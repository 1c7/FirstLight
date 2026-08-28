// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FirstLight",
    platforms: [.macOS(.v13)],
    targets: [
        // All app code lives in a library target: Xcode Previews can't
        // render executable targets (they require ENABLE_DEBUG_DYLIB, which
        // a SwiftPM manifest can't set), but library targets preview fine.
        .target(
            name: "FirstLightCore",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AppKit"),
                .linkedFramework("CoreFoundation"),
            ]
        ),
        .executableTarget(
            name: "FirstLight",
            dependencies: ["FirstLightCore"],
            path: "Sources/FirstLight"
        ),
        .testTarget(
            name: "FirstLightCoreTests",
            dependencies: ["FirstLightCore"]
        ),
    ]
)
