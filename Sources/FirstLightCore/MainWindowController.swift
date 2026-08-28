import AppKit
import SwiftUI

// Bigger, on-screen view of the same data the menu bar title shows.
// Lifecycle: created lazily on first click, then kept alive and just
// shown/hidden. Closing the window (red button) only orders it out --
// it must NOT quit the app, since the status item keeps running in the
// background. See AppDelegate's applicationShouldTerminateAfterLastWindowClosed.
final class MainWindowController: NSWindowController {
    var onOpenSettings: (() -> Void)?
    var onOpenDebug: (() -> Void)?

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
        window.backgroundColor = NSColor(red: 0.94, green: 0.91, blue: 0.87, alpha: 1.0)
        window.center()
        self.init(window: window)
        let hosting = NSHostingController(rootView: MainContentView(
            model: model,
            onSettings: { [weak self] in self?.onOpenSettings?() },
            onDebug: { [weak self] in self?.onOpenDebug?() }
        ))
        hosting.sizingOptions = []
        contentViewController = hosting
        window.setContentSize(NSSize(width: 440, height: 600))
        localize()
    }

    func localize() {
        window?.title = L10n.text("醒后见光", "FirstLight")
        model.localeRevision += 1
    }

    func setDebugSimulationActive(_ active: Bool) {
        model.isDebugSimulation = active
    }

    /// Refreshes every field from the current sensor/dose state. Safe to
    /// call whether or not the window is currently visible.
    func update(lux: Double?, accumulatedMinutes: Double, formatter: NumberFormatter) {
        model.apply(lux: lux, accumulatedMinutes: accumulatedMinutes, formatter: formatter)
    }
}

// MARK: - Design Tokens

/// Warm color palette matching the design mockup.
private enum DesignTokens {
    // Background gradient
    static let bgTop = Color(red: 1.0, green: 0.99, blue: 0.97)        // #fffdf8
    static let bgMid = Color(red: 0.98, green: 0.96, blue: 0.93)       // #faf5ec
    static let bgBottom = Color(red: 0.96, green: 0.93, blue: 0.89)    // #f4eee3

    // Text colors
    static let textPrimary = Color(red: 0.133, green: 0.114, blue: 0.090)  // #221d17
    static let textSecondary = Color(red: 0.133, green: 0.114, blue: 0.090).opacity(0.55)
    static let textTertiary = Color(red: 0.133, green: 0.114, blue: 0.090).opacity(0.4)
    static let textDim = Color(red: 0.133, green: 0.114, blue: 0.090).opacity(0.5)

    // Accent colors
    static let accentTiming = Color(red: 0.80, green: 0.52, blue: 0.18)    // warm amber ~oklch(0.60 0.14 58)
    static let accentDone = Color(red: 0.30, green: 0.60, blue: 0.35)      // green ~oklch(0.55 0.14 145)
    static let accentDim = Color(red: 0.45, green: 0.50, blue: 0.62)       // muted blue ~oklch(0.55 0.06 250)

    // Separator
    static let separator = Color(red: 0.133, green: 0.114, blue: 0.090).opacity(0.08)

    // Traffic light dots
    static let trafficDot = Color(red: 0.133, green: 0.114, blue: 0.090).opacity(0.16)

    // Ring track
    static let ringTrack = Color(red: 0.133, green: 0.114, blue: 0.090).opacity(0.10)

    // Inner text
    static let innerText = Color(red: 0.102, green: 0.086, blue: 0.067)    // #1a1611
}

// MARK: - View Model

@MainActor
final class MainViewModel: ObservableObject {
    @Published var luxText = "--"
    @Published var luxValue: Double = 0
    @Published var statusText = ""
    @Published var statusColor: NSColor = .secondaryLabelColor
    @Published var progress = 0.0
    @Published var progressText = "—"
    @Published var adviceText = ""
    @Published var isDebugSimulation = false
    @Published var localeRevision = 0

    // New v3 design fields
    @Published var isAchieved = false
    @Published var isTimerActive = false      // light is above threshold and counting
    @Published var remainingSeconds: Int = 0  // seconds remaining to goal
    @Published var goalMinutes: Double = 0
    @Published var accMinutes: Double = 0

    func apply(lux: Double?, accumulatedMinutes: Double, formatter: NumberFormatter) {
        accMinutes = accumulatedMinutes
        goalMinutes = DoseCalculator.targetEffectiveMinutes

        guard let lux else {
            luxText = "--"
            luxValue = 0
            statusText = L10n.text("传感器不可用", "Sensor unavailable")
            statusColor = .systemOrange
            progress = 0
            progressText = "—"
            adviceText = L10n.text("打开调试面板可查看诊断信息", "Open Debug States to view diagnostics")
            isAchieved = false
            isTimerActive = false
            remainingSeconds = 0
            return
        }

        luxText = formatter.string(from: NSNumber(value: lux)) ?? "\(Int(lux))"
        luxValue = lux
        let target = DoseCalculator.targetEffectiveMinutes
        progress = target > 0 ? min(accumulatedMinutes / target, 1) : 0
        progressText = String(format: "%.1f / %.1f %@", accumulatedMinutes, target,
                              L10n.text("分钟", "min"))

        // Compute remaining real minutes → seconds
        if DoseCalculator.isAchieved(accumulatedMinutes) {
            isAchieved = true
            isTimerActive = false
            remainingSeconds = 0
            statusText = L10n.text("今日目标已达成 ✓", "Today's goal achieved ✓")
            statusColor = .systemGreen
            adviceText = L10n.text("今天的晨光已经晒够啦", "You've had enough morning light today")
        } else if DoseCalculator.isCurrentLightUseful(lux) {
            isAchieved = false
            isTimerActive = true
            if let remaining = DoseCalculator.remainingRealMinutes(
                currentLux: lux, accumulatedEffectiveMinutes: accumulatedMinutes)
            {
                remainingSeconds = max(0, Int(remaining * 60))
                adviceText = L10n.text("保持现在的亮度，别回到屋里。", "Keep this brightness, stay outside.")
            }
            statusText = L10n.text("正在积累有效光照", "Effective light in progress")
            statusColor = .systemBlue
        } else {
            isAchieved = false
            isTimerActive = false
            if let remaining = DoseCalculator.remainingRealMinutes(
                currentLux: max(lux, DoseCalculator.uselessBelowLux),
                accumulatedEffectiveMinutes: accumulatedMinutes)
            {
                remainingSeconds = max(0, Int(remaining * 60))
            }
            statusText = L10n.text("光照不足", "Light is too dim")
            statusColor = .secondaryLabelColor
            adviceText = L10n.text("走到户外或阳台。室内几百 lux 不算，户外随手就是几千。",
                                   "Find a bright, open spot outdoors. Indoor light won't cut it.")
        }
    }

    var verdict: String {
        if isAchieved {
            return L10n.text("今天晒够了", "Done for today")
        } else if isTimerActive {
            return L10n.text("正在计时", "Counting")
        } else {
            return L10n.text("还不够亮", "Too dim")
        }
    }

    var accentColor: Color {
        if isAchieved {
            return DesignTokens.accentDone
        } else if isTimerActive {
            return DesignTokens.accentTiming
        } else {
            return DesignTokens.accentDim
        }
    }

    var haloGradient: RadialGradient {
        if isTimerActive || isAchieved {
            return RadialGradient(
                colors: [Color(red: 1, green: 0.67, blue: 0.20).opacity(0.22),
                         Color(red: 1, green: 0.67, blue: 0.20).opacity(0)],
                center: .center, startRadius: 0, endRadius: 125)
        } else {
            return RadialGradient(
                colors: [Color(red: 0.35, green: 0.47, blue: 0.67).opacity(0.10),
                         Color(red: 0.35, green: 0.47, blue: 0.67).opacity(0)],
                center: .center, startRadius: 0, endRadius: 125)
        }
    }

    var bigCountdownText: String {
        let mm = remainingSeconds / 60
        let ss = remainingSeconds % 60
        return String(format: "%d:%02d", mm, ss)
    }

    var bigLabel: String {
        if isAchieved {
            return L10n.text("分钟 · 已达成", "min · achieved")
        } else if isTimerActive {
            return L10n.text("还 需 要", "remaining")
        } else {
            return L10n.text("暂停中 · 还需要", "paused · remaining")
        }
    }

    var bigValue: String {
        if isAchieved {
            return "\(Int(DoseCalculator.targetEffectiveMinutes.rounded()))"
        } else {
            return bigCountdownText
        }
    }
}

// MARK: - Tab Enum

enum MainTab: CaseIterable {
    case coach
    case number
    case why
}

// MARK: - Main Content View

struct MainContentView: View {
    @ObservedObject var model: MainViewModel
    var onSettings: () -> Void
    var onDebug: () -> Void

    @State private var selectedTab: MainTab = .coach

    var body: some View {
        let _ = model.localeRevision
        ZStack {
            // Warm gradient background
            LinearGradient(
                colors: [DesignTokens.bgTop, DesignTokens.bgMid, DesignTokens.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title bar spacer (for traffic lights area)
                HStack(spacing: 0) {
                    Spacer()
                }
                .frame(height: 40)

                // Tab bar
                tabBar

                // Content area
                Group {
                    switch selectedTab {
                    case .coach:
                        coachView
                    case .number:
                        numberView
                    case .why:
                        whyView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 4) {
            tabItem(
                title: L10n.text("今日光照进度", "Light Progress"),
                subtitle: L10n.text("还差多久达标", "Time to goal"),
                tab: .coach
            )
            tabItem(
                title: L10n.text("实时照度大字", "Live Lux"),
                subtitle: L10n.text("只看当前 lux 数值", "Current lux reading"),
                tab: .number
            )
            tabItem(
                title: L10n.text("为什么要见光", "Why Light"),
                subtitle: L10n.text("30 秒读懂原理", "30s science primer"),
                tab: .why
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 2)
        .overlay(alignment: .bottom) {
            DesignTokens.separator
                .frame(height: 1)
        }
    }

    private func tabItem(title: String, subtitle: String, tab: MainTab) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: { selectedTab = tab }) {
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? DesignTokens.textPrimary : DesignTokens.textDim)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(DesignTokens.textTertiary)
            }
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                if isSelected {
                    Rectangle()
                        .fill(DesignTokens.textPrimary)
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Coach View (今日光照进度)

    private var coachView: some View {
        VStack(spacing: 0) {
            // Verdict title
            Text(model.verdict)
                .font(.custom("Instrument Serif", size: 34).italic())
                .foregroundColor(model.accentColor)
                .padding(.top, 30)

            if model.isAchieved {
                // Done state: checkmark
                Spacer()
                ZStack {
                    Circle()
                        .fill(model.haloGradient)
                        .frame(width: 96, height: 96)
                    Text("✓")
                        .font(.system(size: 46))
                        .foregroundColor(model.accentColor)
                }
                Spacer()
            } else {
                // Active/paused state: ring with countdown
                ringView
                    .padding(.top, 4)

                // Lux indicator
                HStack(spacing: 9) {
                    Circle()
                        .fill(model.accentColor)
                        .frame(width: 7, height: 7)
                    Text(L10n.text("照度 \(model.luxText) lux", "Lux \(model.luxText)"))
                        .font(.system(size: 15).monospacedDigit())
                        .tracking(0.3)
                        .foregroundColor(DesignTokens.textPrimary.opacity(0.82))
                }
                .padding(.top, 4)
            }

            // Hint text
            Text(model.adviceText)
                .font(.system(size: 13.5))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundColor(DesignTokens.textSecondary)
                .padding(.horizontal, 44)
                .padding(.top, 16)

            Spacer(minLength: 0)
        }
    }

    private var ringView: some View {
        ZStack {
            // Glow halo
            Circle()
                .fill(model.haloGradient)
                .frame(width: 250, height: 250)
                .modifier(GlowPulseModifier(isActive: model.isTimerActive))

            // Ring
            Circle()
                .stroke(DesignTokens.ringTrack, lineWidth: 4)
                .frame(width: 264, height: 264)

            Circle()
                .trim(from: 0, to: model.progress)
                .stroke(model.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 264, height: 264)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 14) {
                Text(model.bigValue)
                    .font(.system(size: 76, weight: .medium).monospacedDigit())
                    .tracking(-3)
                    .foregroundColor(DesignTokens.innerText)

                Text(model.bigLabel)
                    .font(.system(size: 10.5))
                    .tracking(2.5)
                    .foregroundColor(DesignTokens.textPrimary.opacity(0.45))
            }
        }
        .frame(width: 300, height: 300)
    }

    // MARK: - Number View (实时照度大字)

    private var numberView: some View {
        VStack(spacing: 0) {
            Spacer()
            let digits = model.luxText.replacingOccurrences(of: ",", with: "").count
            let fontSize: CGFloat = digits >= 6 ? 108 : digits >= 5 ? 128 : digits >= 4 ? 148 : 168
            Text(model.luxText)
                .font(.system(size: fontSize, weight: .medium).monospacedDigit())
                .tracking(-fontSize * 0.05)
                .foregroundColor(DesignTokens.innerText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(L10n.text("勒克斯 LUX", "LUX"))
                .font(.system(size: 22, weight: .medium))
                .tracking(3.5)
                .foregroundColor(DesignTokens.textPrimary.opacity(0.6))
                .padding(.top, 22)
            Spacer()
        }
        .padding(.bottom, 24)
    }

    // MARK: - Why View (为什么要见光)

    private var whyView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            Text(L10n.text("光，是生物钟唯一能对表的信号。",
                           "Light is the only signal that can reset your body clock."))
                .font(.custom("Instrument Serif", size: 27))
                .lineSpacing(6)
                .foregroundColor(DesignTokens.innerText)
                .padding(.top, 26)

            VStack(alignment: .leading, spacing: 18) {
                whyItem(
                    number: "01",
                    text: L10n.text(
                        "醒后见到强光，视网膜会向大脑发出「白天开始」的信号，当天的生物钟就此归零。",
                        "Strong light after waking sends a 'daytime starts' signal from the retina to the brain, resetting your circadian clock.")
                )
                whyItem(
                    number: "02",
                    text: L10n.text(
                        "归零之后约 14 小时，褪黑素才开始分泌。见光越早，晚上就困得越早。",
                        "About 14 hours after the reset, melatonin begins to flow. The earlier you see light, the earlier you'll feel sleepy.")
                )
                whyItem(
                    number: "03",
                    text: L10n.text(
                        "起作用的是亮度。室内只有几百 lux，阴天户外也上万 —— 所以必须出门。",
                        "What matters is brightness. Indoors is only a few hundred lux; even an overcast sky is tens of thousands — so you must go outside.")
                )
            }
            .padding(.top, 20)

            Spacer(minLength: 0)

            // Bottom tip
            VStack(alignment: .leading, spacing: 0) {
                DesignTokens.separator
                    .frame(height: 1)
                    .padding(.bottom, 14)

                Text(L10n.text("醒后一小时内，户外待 10–20 分钟。隔着玻璃效果减半，别戴墨镜。",
                               "Within 1 hour of waking, spend 10–20 min outdoors. Glass halves the effect; don't wear sunglasses."))
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .foregroundColor(DesignTokens.textSecondary)
            }
        }
        .padding(.horizontal, 34)
        .padding(.bottom, 28)
    }

    private func whyItem(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(model.accentColor)
                .frame(width: 20, alignment: .leading)
                .padding(.top, 3)
            Text(text)
                .font(.system(size: 14))
                .lineSpacing(5)
                .foregroundColor(DesignTokens.textPrimary.opacity(0.78))
        }
    }
}

// MARK: - Glow Pulse Animation

struct GlowPulseModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? (isPulsing ? 0.8 : 0.45) : 0.3)
            .scaleEffect(isActive ? (isPulsing ? 1.05 : 1.0) : 1.0)
            .animation(
                isActive
                    ? .easeInOut(duration: 3).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onAppear { isPulsing = true }
            .onChange(of: isActive) { newValue in
                isPulsing = newValue
            }
    }
}

// MARK: - Previews

@MainActor
private func previewModel(lux: Double?, minutes: Double) -> MainViewModel {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    let model = MainViewModel()
    model.apply(lux: lux, accumulatedMinutes: minutes, formatter: formatter)
    return model
}

#Preview("正在计时") {
    MainContentView(
        model: previewModel(lux: 24_930, minutes: 7),
        onSettings: {}, onDebug: {}
    )
    .frame(width: 440, height: 600)
}

#Preview("光照不足") {
    MainContentView(
        model: previewModel(lux: 35, minutes: 12),
        onSettings: {}, onDebug: {}
    )
    .frame(width: 440, height: 600)
}

#Preview("已达标") {
    MainContentView(
        model: previewModel(lux: 10_000, minutes: 25),
        onSettings: {}, onDebug: {}
    )
    .frame(width: 440, height: 600)
}

#Preview("传感器不可用") {
    MainContentView(
        model: previewModel(lux: nil, minutes: 0),
        onSettings: {}, onDebug: {}
    )
    .frame(width: 440, height: 600)
}
