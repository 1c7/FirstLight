import AppKit
import SwiftUI

/// 主窗口顶部的三个功能页。
enum MainTab: CaseIterable {
    case progress
    case liveLux
    case whyLight
}

/// 主窗口的 SwiftUI 内容层。
///
/// 本视图只负责布局和交互；传感器、计时与持久化均由外层控制器和模型处理。
struct MainContentView: View {
    @ObservedObject var model: MainViewModel

    @State private var selectedTab: MainTab = .progress
    @State private var hoveredTab: MainTab?

    var body: some View {
        // 读取修订号以便应用内切换语言时强制重新计算 L10n 文案。
        let _ = model.localeRevision
        ZStack {
            LinearGradient(
                colors: [
                    FirstLightDesignTokens.backgroundTop,
                    FirstLightDesignTokens.backgroundMiddle,
                    FirstLightDesignTokens.backgroundBottom,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                tabBar

                Group {
                    switch selectedTab {
                    case .progress:
                        progressView
                    case .liveLux:
                        liveLuxView
                    case .whyLight:
                        whyLightView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: 顶部 Tab

    private var tabBar: some View {
        HStack(spacing: 4) {
            tabButton(title: L10n.text("光照进度", "Progress"), tab: .progress)
            tabButton(title: L10n.text("实时照度", "Live Lux"), tab: .liveLux)
            tabButton(title: L10n.text("为什么见光", "Why Light"), tab: .whyLight)
        }
        .padding(.horizontal, 20)
        .padding(.top, 2)
        .overlay(alignment: .bottom) {
            FirstLightDesignTokens.separator.frame(height: 1)
        }
    }

    private func tabButton(title: String, tab: MainTab) -> some View {
        let isSelected = selectedTab == tab
        let isHovered = hoveredTab == tab

        return Button(action: { selectedTab = tab }) {
            Text(title)
                .font(.system(size: 14, weight: isHovered ? .semibold : .medium))
                .foregroundColor(
                    isHovered
                        ? FirstLightDesignTokens.tabHoverText
                        : isSelected
                            ? FirstLightDesignTokens.textPrimary
                            : FirstLightDesignTokens.textDim
                )
                .frame(
                    maxWidth: .infinity,
                    minHeight: FirstLightDesignTokens.tabMinimumHeight
                )
                // 明确整块矩形都是命中区域，而不只是文字轮廓。
                .contentShape(Rectangle())
                .background {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(
                            isHovered
                                ? FirstLightDesignTokens.tabHoverBackground
                                : Color.clear
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(
                                    isHovered
                                        ? FirstLightDesignTokens.tabHoverBorder
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        }
                        .padding(.vertical, 3)
                }
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle()
                            .fill(FirstLightDesignTokens.textPrimary)
                            .frame(height: 2)
                    }
                }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredTab = hovering ? tab : (hoveredTab == tab ? nil : hoveredTab)
            // 直接设置光标，避免视图重建时 push/pop 栈失衡导致光标残留。
            (hovering ? NSCursor.pointingHand : NSCursor.arrow).set()
        }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    // MARK: 光照进度

    private var progressView: some View {
        VStack(spacing: 0) {
            Text(model.verdict)
                .font(.custom("Instrument Serif", size: 34).italic())
                .foregroundColor(model.accentColor)
                .padding(.top, 30)

            if model.isAchieved {
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
                Text(L10n.text("照度 \(model.luxText) lux", "\(model.luxText) lux"))
                    .font(.system(size: 20, weight: .medium).monospacedDigit())
                    .tracking(0.3)
                    .foregroundColor(FirstLightDesignTokens.textPrimary.opacity(0.82))
                    .padding(.top, 10)

                progressRing.padding(.top, 2)
            }

            Text(model.adviceText)
                .font(.system(size: 14.5))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundColor(FirstLightDesignTokens.textSecondary)
                .padding(.horizontal, 30)
                .padding(.top, 12)

            Spacer(minLength: 0)
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .fill(model.haloGradient)
                .frame(width: 250, height: 250)
                .modifier(GlowPulseModifier(isActive: model.isTimerActive))

            Circle()
                .stroke(FirstLightDesignTokens.ringTrack, lineWidth: 4)
                .frame(width: 264, height: 264)

            Circle()
                .trim(from: 0, to: model.progress)
                .stroke(
                    model.accentColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 264, height: 264)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 14) {
                Text(model.bigValue)
                    .font(.system(size: 76, weight: .medium).monospacedDigit())
                    .tracking(-3)
                    .foregroundColor(FirstLightDesignTokens.innerText)

                Text(model.bigLabel)
                    .font(.system(size: 13))
                    .tracking(2)
                    .foregroundColor(FirstLightDesignTokens.textPrimary.opacity(0.45))
            }
        }
        .frame(width: 300, height: 300)
    }

    // MARK: 实时照度

    private var liveLuxView: some View {
        VStack(spacing: 0) {
            Spacer()
            let digitCount = model.luxText.replacingOccurrences(of: ",", with: "").count
            let fontSize: CGFloat = digitCount >= 6
                ? 108
                : digitCount >= 5
                    ? 128
                    : digitCount >= 4 ? 148 : 168

            Text(model.luxText)
                .font(.system(size: fontSize, weight: .medium).monospacedDigit())
                .tracking(-fontSize * 0.05)
                .foregroundColor(FirstLightDesignTokens.innerText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(L10n.text("勒克斯 LUX", "LUX"))
                .font(.system(size: 22, weight: .medium))
                .tracking(3.5)
                .foregroundColor(FirstLightDesignTokens.textPrimary.opacity(0.6))
                .padding(.top, 22)
            Spacer()
        }
        .padding(.bottom, 24)
    }

    // MARK: 为什么见光

    private var whyLightView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.text(
                "光，是生物钟唯一能对表的信号。",
                "Light is the only signal that can reset your body clock."
            ))
            .font(.custom("Instrument Serif", size: 27))
            .lineSpacing(6)
            .foregroundColor(FirstLightDesignTokens.innerText)
            .padding(.top, 26)

            VStack(alignment: .leading, spacing: 18) {
                explanationItem(
                    number: "01",
                    text: L10n.text(
                        "醒后见到强光，视网膜会向大脑发出「白天开始」的信号，当天的生物钟就此归零。",
                        "Strong light after waking sends a 'daytime starts' signal from the retina to the brain, resetting your circadian clock."
                    )
                )
                explanationItem(
                    number: "02",
                    text: L10n.text(
                        "归零之后约 14 小时，褪黑素才开始分泌。见光越早，晚上就困得越早。",
                        "About 14 hours after the reset, melatonin begins to flow. The earlier you see light, the earlier you'll feel sleepy."
                    )
                )
                explanationItem(
                    number: "03",
                    text: L10n.text(
                        "起作用的是亮度。室内只有几百 lux，阴天户外也上万 —— 所以必须出门。",
                        "What matters is brightness. Indoors is only a few hundred lux; even an overcast sky is tens of thousands — so you must go outside."
                    )
                )
            }
            .padding(.top, 20)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 0) {
                FirstLightDesignTokens.separator
                    .frame(height: 1)
                    .padding(.bottom, 14)

                Text(L10n.text(
                    "醒后一小时内，户外待 10–20 分钟。隔着玻璃效果减半，别戴墨镜。",
                    "Within 1 hour of waking, spend 10–20 min outdoors. Glass halves the effect; don't wear sunglasses."
                ))
                .font(.system(size: 13))
                .lineSpacing(4)
                .foregroundColor(FirstLightDesignTokens.textSecondary)
            }
        }
        .padding(.horizontal, 34)
        .padding(.bottom, 28)
    }

    private func explanationItem(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(model.accentColor)
                .frame(width: 20, alignment: .leading)
                .padding(.top, 3)
            Text(text)
                .font(.system(size: 14))
                .lineSpacing(5)
                .foregroundColor(FirstLightDesignTokens.textPrimary.opacity(0.78))
        }
    }
}

/// 有效光照计时时，为中心光晕提供缓慢呼吸效果。
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
            .onChange(of: isActive) { isPulsing = $0 }
    }
}

// MARK: 预览

@MainActor
private func previewModel(lux: Double?, minutes: Double) -> MainViewModel {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    formatter.locale = L10n.locale
    let model = MainViewModel()
    model.apply(lux: lux, accumulatedMinutes: minutes, formatter: formatter)
    return model
}

#Preview("正在计时") {
    MainContentView(model: previewModel(lux: 24_930, minutes: 7))
        .frame(width: 440, height: 600)
}

#Preview("光照不足") {
    MainContentView(model: previewModel(lux: 35, minutes: 12))
        .frame(width: 440, height: 600)
}

#Preview("已达标") {
    MainContentView(model: previewModel(lux: 10_000, minutes: 25))
        .frame(width: 440, height: 600)
}

#Preview("传感器不可用") {
    MainContentView(model: previewModel(lux: nil, minutes: 0))
        .frame(width: 440, height: 600)
}
