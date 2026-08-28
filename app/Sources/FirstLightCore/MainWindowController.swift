import AppKit
import SwiftUI

/// 管理主窗口的 AppKit 生命周期，并将实时数据传递给 SwiftUI 模型。
///
/// 主窗口首次点击菜单栏时才创建，关闭红色按钮只隐藏窗口，不会结束后台的照度
/// 采集。界面布局位于 `MainContentView.swift`，展示状态位于
/// `MainViewModel.swift`。
final class MainWindowController: NSWindowController {
    private let model = MainViewModel()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor(
            red: 0.94,
            green: 0.91,
            blue: 0.87,
            alpha: 1.0
        )
        window.center()

        self.init(window: window)

        let hostingController = NSHostingController(
            rootView: MainContentView(model: model)
        )
        // 主窗口尺寸由 NSWindow 管理，避免 SwiftUI 内容反向修改窗口大小。
        hostingController.sizingOptions = []
        contentViewController = hostingController
        window.setContentSize(NSSize(width: 440, height: 600))
        localize()
    }

    /// 刷新窗口标题和所有由当前语言动态计算的 SwiftUI 文案。
    func localize() {
        window?.title = L10n.text("醒后见光", "FirstLight")
        model.localeRevision += 1
    }

    func setDebugSimulationActive(_ active: Bool) {
        model.isDebugSimulation = active
    }

    /// 使用当前传感器和剂量状态刷新界面；窗口隐藏时调用也安全。
    func update(
        lux: Double?,
        accumulatedMinutes: Double,
        formatter: NumberFormatter
    ) {
        model.apply(
            lux: lux,
            accumulatedMinutes: accumulatedMinutes,
            formatter: formatter
        )
    }
}
