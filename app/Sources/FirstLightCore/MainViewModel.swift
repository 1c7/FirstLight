import AppKit
import SwiftUI

/// 主窗口所需的可观察状态。
///
/// 传感器读数与剂量计算由 `AppDelegate` 驱动；本模型只负责把原始数据转换成
/// 适合展示的状态和双语文案，不直接读取硬件或写入持久化文件。
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

    @Published var isAchieved = false
    @Published var isTimerActive = false
    @Published var remainingSeconds = 0
    @Published var goalMinutes: Double = 0
    @Published var accumulatedMinutes: Double = 0

    /// 使用最新的传感器读数和今日累计量刷新全部展示字段。
    func apply(lux: Double?, accumulatedMinutes: Double, formatter: NumberFormatter) {
        self.accumulatedMinutes = accumulatedMinutes
        goalMinutes = DoseCalculator.targetEffectiveMinutes

        guard let lux else {
            applySensorUnavailableState()
            return
        }

        luxText = formatter.string(from: NSNumber(value: lux)) ?? "\(Int(lux))"
        luxValue = lux
        let target = DoseCalculator.targetEffectiveMinutes
        progress = target > 0 ? min(accumulatedMinutes / target, 1) : 0
        progressText = String(
            format: "%.1f / %.1f %@",
            accumulatedMinutes,
            target,
            L10n.text("分钟", "min")
        )

        if DoseCalculator.isAchieved(accumulatedMinutes) {
            applyAchievedState()
        } else if DoseCalculator.isCurrentLightUseful(lux) {
            applyActiveState(lux: lux, accumulatedMinutes: accumulatedMinutes)
        } else {
            applyPausedState(lux: lux, accumulatedMinutes: accumulatedMinutes)
        }
    }

    var verdict: String {
        if isAchieved { return L10n.text("今天晒够了", "Done for today") }
        if isTimerActive { return L10n.text("正在计时", "Counting") }
        return L10n.text("还不够亮", "Too dim")
    }

    var accentColor: Color {
        if isAchieved { return FirstLightDesignTokens.accentDone }
        if isTimerActive { return FirstLightDesignTokens.accentTiming }
        return FirstLightDesignTokens.accentDim
    }

    var haloGradient: RadialGradient {
        if isTimerActive || isAchieved {
            return RadialGradient(
                colors: [
                    Color(red: 1, green: 0.67, blue: 0.20).opacity(0.22),
                    Color(red: 1, green: 0.67, blue: 0.20).opacity(0),
                ],
                center: .center,
                startRadius: 0,
                endRadius: 125
            )
        }
        return RadialGradient(
            colors: [
                Color(red: 0.35, green: 0.47, blue: 0.67).opacity(0.10),
                Color(red: 0.35, green: 0.47, blue: 0.67).opacity(0),
            ],
            center: .center,
            startRadius: 0,
            endRadius: 125
        )
    }

    var bigCountdownText: String {
        String(format: "%d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    var bigLabel: String {
        if isAchieved { return L10n.text("分钟 · 已达成", "min · achieved") }
        if isTimerActive { return L10n.text("还 需 要", "remaining") }
        return L10n.text("暂停中 · 还需要", "paused · remaining")
    }

    var bigValue: String {
        isAchieved
            ? "\(Int(DoseCalculator.targetEffectiveMinutes.rounded()))"
            : bigCountdownText
    }

    private func applySensorUnavailableState() {
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
    }

    private func applyAchievedState() {
        isAchieved = true
        isTimerActive = false
        remainingSeconds = 0
        statusText = L10n.text("今日目标已达成 ✓", "Today's goal achieved ✓")
        statusColor = .systemGreen
        adviceText = L10n.text("今天的晨光已经晒够啦", "You've had enough morning light today")
    }

    private func applyActiveState(lux: Double, accumulatedMinutes: Double) {
        isAchieved = false
        isTimerActive = true
        if let remaining = DoseCalculator.remainingRealMinutes(
            currentLux: lux,
            accumulatedEffectiveMinutes: accumulatedMinutes
        ) {
            remainingSeconds = max(0, Int(remaining * 60))
        }
        adviceText = L10n.text(
            "别戴墨镜，不用直视太阳。让户外光自然进入眼睛就好。",
            "No sunglasses. No need to stare at the sun — just let outdoor light reach your eyes."
        )
        statusText = L10n.text("正在积累有效光照", "Effective light in progress")
        statusColor = .systemBlue
    }

    private func applyPausedState(lux: Double, accumulatedMinutes: Double) {
        isAchieved = false
        isTimerActive = false
        if let remaining = DoseCalculator.remainingRealMinutes(
            currentLux: max(lux, DoseCalculator.uselessBelowLux),
            accumulatedEffectiveMinutes: accumulatedMinutes
        ) {
            remainingSeconds = max(0, Int(remaining * 60))
        }
        statusText = L10n.text("光照不足", "Light is too dim")
        statusColor = .secondaryLabelColor
        adviceText = L10n.text(
            "到户外去，让眼睛接收自然光。别戴墨镜，可以戴帽檐防晒脸。",
            "Go outside and let natural light reach your eyes. No sunglasses — a hat brim is fine."
        )
    }
}
