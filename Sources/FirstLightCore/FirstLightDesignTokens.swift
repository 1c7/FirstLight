import SwiftUI

/// FirstLight 主界面的视觉变量。
///
/// 颜色、透明度和常用尺寸集中在这里，避免视图中散落魔法数字。调整主题时应优先
/// 修改本文件，并检查主窗口的三种状态（计时、过暗、已达标）。
enum FirstLightDesignTokens {
    // MARK: 背景

    static let backgroundTop = Color(red: 1.0, green: 0.99, blue: 0.97)
    static let backgroundMiddle = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let backgroundBottom = Color(red: 0.96, green: 0.93, blue: 0.89)

    // MARK: 文字

    static let textPrimary = Color(red: 0.133, green: 0.114, blue: 0.090)
    static let textSecondary = textPrimary.opacity(0.55)
    static let textDim = textPrimary.opacity(0.5)
    static let innerText = Color(red: 0.102, green: 0.086, blue: 0.067)

    // MARK: 状态色

    static let accentTiming = Color(red: 0.80, green: 0.52, blue: 0.18)
    static let accentDone = Color(red: 0.30, green: 0.60, blue: 0.35)
    static let accentDim = Color(red: 0.45, green: 0.50, blue: 0.62)

    // MARK: 控件

    static let separator = textPrimary.opacity(0.08)
    static let ringTrack = textPrimary.opacity(0.10)

    /// Tab hover 使用较明显的暖色底；透明度刻意高于普通分隔线，确保能被感知。
    static let tabHoverBackground = accentTiming.opacity(0.24)
    static let tabHoverBorder = accentTiming.opacity(0.48)
    static let tabHoverText = textPrimary
    static let tabMinimumHeight: CGFloat = 50
}
