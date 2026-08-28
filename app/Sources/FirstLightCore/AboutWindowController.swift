import AppKit
import SwiftUI

/// 管理“关于 FirstLight”独立窗口与多语言刷新。
final class AboutWindowController: NSWindowController {
    private let model = AboutViewModel()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.center()
        self.init(window: window)

        let hosting = NSHostingController(rootView: AboutContentView(model: model))
        hosting.sizingOptions = []
        contentViewController = hosting
        window.setContentSize(NSSize(width: 380, height: 380))
        localize()
    }

    func localize() {
        window?.title = L10n.text("关于 醒后见光", "About FirstLight")
        model.localeRevision += 1
    }
}

@MainActor
final class AboutViewModel: ObservableObject {
    @Published var localeRevision = 0
}

struct AboutContentView: View {
    @ObservedObject var model: AboutViewModel

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.2"
        return "v\(version)"
    }

    var body: some View {
        let _ = model.localeRevision
        VStack(spacing: 16) {
            // App Icon
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
            }

            // App Name & Version
            VStack(spacing: 4) {
                Text(L10n.text("醒后见光 (FirstLight)", "FirstLight"))
                    .font(.system(size: 18, weight: .bold))
                Text(versionString)
                    .font(.system(size: 12))
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
            }

            // Tagline
            Text(L10n.text(
                "在 Mac 菜单栏实时监测早晨见光量，轻松调节作息、告别晚睡晚起。",
                "Track morning bright light from your Mac menu bar to fix your sleep schedule."
            ))
            .font(.system(size: 12))
            .multilineTextAlignment(.center)
            .foregroundColor(Color(nsColor: .secondaryLabelColor))
            .padding(.horizontal, 24)

            Divider()
                .padding(.horizontal, 24)

            // Author & Email Info
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(L10n.text("作者：", "Author:"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                        .frame(width: 50, alignment: .leading)
                    Text("郑诚（Cheng Zheng）")
                        .font(.system(size: 12))
                }

                HStack(spacing: 8) {
                    Text(L10n.text("邮箱：", "Email:"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                        .frame(width: 50, alignment: .leading)
                    Link("chengzheng.dev@gmail.com", destination: URL(string: "mailto:chengzheng.dev@gmail.com")!)
                        .font(.system(size: 12))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 36)

            Spacer()

            // Action Button
            Button(action: {
                if let url = URL(string: "https://github.com/1c7/FirstLight") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 12))
                    Text(L10n.text("访问 GitHub 仓库", "View on GitHub"))
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 22)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
