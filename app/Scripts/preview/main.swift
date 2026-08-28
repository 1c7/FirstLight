import AppKit

// Offscreen render of all three windows -> /tmp/fl-main.png,
// /tmp/fl-settings.png, /tmp/fl-debug.png. Fastest way to eyeball a UI
// change without launching the app or clicking the status item.

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let formatter = NumberFormatter()
formatter.numberStyle = .decimal
formatter.maximumFractionDigits = 0
formatter.locale = Locale(identifier: "zh_CN")

let main = MainWindowController()
main.update(lux: 35, accumulatedMinutes: 12.0, formatter: formatter)

let settings = SettingsWindowController()

let debug = DebugWindowController()
debug.diagnosticsProvider = { AmbientLightSensor.diagnosticReport() }
debug.refreshDiagnostics()

func render(_ wc: NSWindowController, to path: String) {
    guard let window = wc.window, let contentView = window.contentView else {
        fatalError("no window for \(path)")
    }
    window.layoutIfNeeded()
    contentView.layoutSubtreeIfNeeded()

    let bounds = contentView.bounds
    FileHandle.standardError.write(Data("RENDER \(path) windowFrame=\(window.frame) contentBounds=\(bounds) fits=\(contentView.fittingSize)\n".utf8))
    let scale = 2
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(bounds.width) * scale,
        pixelsHigh: Int(bounds.height) * scale,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = bounds.size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    contentView.cacheDisplay(in: bounds, to: rep)
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: path))
    print("\(path) bounds=\(bounds)")
}

render(main, to: "/tmp/fl-main.png")
render(settings, to: "/tmp/fl-settings.png")
render(debug, to: "/tmp/fl-debug.png")
exit(0)
