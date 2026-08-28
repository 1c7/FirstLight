import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    var onLanguageChange: (() -> Void)?

    private let model = SettingsViewModel()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 230),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.center()
        self.init(window: window)
        // Fixed-size windows: don't let the SwiftUI content drive sizing.
        let hosting = NSHostingController(rootView: SettingsContentView(
            model: model,
            onSelectLanguage: { [weak self] language in
                self?.applyLanguage(language)
            }
        ))
        hosting.sizingOptions = []
        contentViewController = hosting
        window.setContentSize(NSSize(width: 420, height: 230))
        localize()
    }

    func localize() {
        window?.title = L10n.text("设置", "Settings")
        model.selectedLanguage = L10n.language
        model.localeRevision += 1
    }

    private func applyLanguage(_ language: AppLanguage) {
        // Also fires when localize() syncs the selection back to the same
        // value -- only a real switch should trigger a global re-localize.
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
                        Text(L10n.languageName(language)).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 150)
                .onChange(of: model.selectedLanguage) { onSelectLanguage($0) }
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 28)
        .padding(.top, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    SettingsContentView(model: SettingsViewModel(), onSelectLanguage: { _ in })
        .frame(width: 420, height: 230)
}
