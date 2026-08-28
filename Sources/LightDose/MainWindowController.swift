import AppKit

// Bigger, on-screen view of the same data the menu bar title shows.
// Pure AppKit, no nib/storyboard (this project has no Xcode project to
// hold one) -- built with NSStackView + Auto Layout by hand.
//
// Lifecycle: created lazily on first click, then kept alive and just
// shown/hidden. Closing the window (red button) only orders it out --
// it must NOT quit the app, since the status item needs to keep
// running in the background. See AppDelegate's
// applicationShouldTerminateAfterLastWindowClosed override.
final class MainWindowController: NSWindowController {
    private let luxValueLabel = NSTextField(labelWithString: "--")
    private let luxUnitLabel = NSTextField(labelWithString: "lux")
    private let statusLabel = NSTextField(labelWithString: "")
    private let progressBar = NSProgressIndicator()
    private let progressLabel = NSTextField(labelWithString: "")
    private let adviceLabel = NSTextField(labelWithString: "")

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 440),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "光照打卡"
        window.center()
        // Don't let AppKit deallocate the window on close -- we reuse
        // the same instance every time the status item is clicked again.
        window.isReleasedWhenClosed = false
        self.init(window: window)
        setUpContent()
    }

    private func setUpContent() {
        guard let contentView = window?.contentView else { return }

        luxValueLabel.font = .monospacedDigitSystemFont(ofSize: 72, weight: .bold)
        luxValueLabel.alignment = .center
        luxValueLabel.lineBreakMode = .byClipping

        luxUnitLabel.font = .systemFont(ofSize: 15)
        luxUnitLabel.textColor = .secondaryLabelColor
        luxUnitLabel.alignment = .center

        statusLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        statusLabel.alignment = .center

        progressBar.style = .bar
        progressBar.isIndeterminate = false
        progressBar.minValue = 0
        progressBar.maxValue = 1
        progressBar.doubleValue = 0
        progressBar.translatesAutoresizingMaskIntoConstraints = false

        progressLabel.font = .systemFont(ofSize: 13)
        progressLabel.textColor = .secondaryLabelColor
        progressLabel.alignment = .center

        adviceLabel.font = .systemFont(ofSize: 14)
        adviceLabel.textColor = .secondaryLabelColor
        adviceLabel.alignment = .center
        adviceLabel.maximumNumberOfLines = 2
        adviceLabel.lineBreakMode = .byWordWrapping

        let luxStack = NSStackView(views: [luxValueLabel, luxUnitLabel])
        luxStack.orientation = .vertical
        luxStack.alignment = .centerX
        luxStack.spacing = 2

        let stack = NSStackView(views: [
            luxStack,
            statusLabel,
            progressBar,
            progressLabel,
            adviceLabel,
        ])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 18
        stack.edgeInsets = NSEdgeInsets(top: 36, left: 32, bottom: 36, right: 32)
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            progressBar.widthAnchor.constraint(equalToConstant: 320),
        ])
    }

    /// Refreshes every label from the current sensor/dose state. Safe to
    /// call whether or not the window is currently visible.
    func update(lux: Double?, accumulatedMinutes: Double, formatter: NumberFormatter) {
        guard let lux = lux else {
            luxValueLabel.stringValue = "--"
            statusLabel.stringValue = "传感器不可用"
            statusLabel.textColor = .labelColor
            progressLabel.stringValue = ""
            adviceLabel.stringValue = ""
            progressBar.doubleValue = 0
            return
        }

        luxValueLabel.stringValue = formatter.string(from: NSNumber(value: lux)) ?? "\(Int(lux))"

        let target = DoseCalculator.targetEffectiveMinutes
        progressBar.doubleValue = target > 0 ? min(accumulatedMinutes / target, 1.0) : 0
        progressLabel.stringValue = String(
            format: "今日有效分钟：%.1f / %.1f 分钟", accumulatedMinutes, target)

        let achieved = DoseCalculator.isAchieved(accumulatedMinutes)
        if achieved {
            statusLabel.stringValue = "今日目标已达成 ✓"
            statusLabel.textColor = .systemGreen
            adviceLabel.stringValue = "今天的晨光已经晒够啦"
        } else if DoseCalculator.isCurrentLightUseful(lux) {
            statusLabel.stringValue = "尚未达标"
            statusLabel.textColor = .labelColor
            if let remaining = DoseCalculator.remainingRealMinutes(
                currentLux: lux, accumulatedEffectiveMinutes: accumulatedMinutes)
            {
                adviceLabel.stringValue = String(format: "按当前光照，还需约 %.0f 分钟", remaining.rounded(.up))
            } else {
                adviceLabel.stringValue = ""
            }
        } else {
            statusLabel.stringValue = "尚未达标"
            statusLabel.textColor = .labelColor
            adviceLabel.stringValue = "光线太暗，户外找个开阔地方"
        }
    }
}
