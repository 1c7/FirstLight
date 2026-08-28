import AppKit
import SwiftUI

/// 管理设置窗口及语言偏好的保存与全局刷新通知。
final class SettingsWindowController: NSWindowController {
    var onLanguageChange: (() -> Void)?

    private let model = SettingsViewModel()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 250),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.center()
        self.init(window: window)
        // 固定尺寸窗口由 AppKit 决定大小，不让 SwiftUI 内容反向驱动窗口尺寸。
        let hosting = NSHostingController(rootView: SettingsContentView(
            model: model,
            onSelectLanguage: { [weak self] language in
                self?.applyLanguage(language)
            }
        ))
        hosting.sizingOptions = []
        contentViewController = hosting
        window.setContentSize(NSSize(width: 440, height: 250))
        localize()
    }

    func localize() {
        window?.title = L10n.text("设置", "Settings")
        model.selectedLanguage = L10n.language
        model.localeRevision += 1
    }

    private func applyLanguage(_ language: AppLanguage) {
        // localize() 同步选中项时也会触发 onChange；只有真实切换才通知全局刷新。
        guard language != L10n.language else { return }
        L10n.language = language
        localize()
        onLanguageChange?()
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedLanguage = L10n.language
    @Published var localeRevision = 0
}

struct SettingsContentView: View {
    @ObservedObject var model: SettingsViewModel
    var onSelectLanguage: (AppLanguage) -> Void

    var body: some View {
        let _ = model.localeRevision
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("设置", "Settings"))
                .font(.system(size: 24, weight: .bold))
            Text(L10n.text(
                "FirstLight 默认跟随 macOS 的语言，也可以只为此应用选择语言。",
                "FirstLight follows the macOS language by default, or you can choose a language just for this app."
            ))
            .font(.system(size: 13))
            .foregroundColor(Color(nsColor: .secondaryLabelColor))
            HStack {
                Text(L10n.text("显示语言", "Display Language"))
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Picker("", selection: $model.selectedLanguage) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(L10n.languageName(
                            language,
                            displayedIn: model.selectedLanguage
                        ))
                        .tag(language)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 150)
                // NSPopUpButton 会缓存 NSMenuItem；语言变化时重建控件才能同步选项标题。
                .id(model.localeRevision)
                .onChange(of: model.selectedLanguage) { onSelectLanguage($0) }
            }
            .padding(.top, 8)

            Divider()
                .padding(.top, 10)

            HStack(spacing: 6) {
                Text(L10n.text("作者：郑诚（Cheng Zheng）", "Author: Cheng Zheng"))
                    .font(.system(size: 11))
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                Text("·")
                    .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                Link("chengzheng.dev@gmail.com", destination: URL(string: "mailto:chengzheng.dev@gmail.com")!)
                    .font(.system(size: 11))
                Spacer()
                Link(L10n.text("GitHub 仓库 ↗", "GitHub Repo ↗"), destination: URL(string: "https://github.com/1c7/FirstLight")!)
                    .font(.system(size: 11))
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    SettingsContentView(model: SettingsViewModel(), onSelectLanguage: { _ in })
        .frame(width: 440, height: 250)
}
