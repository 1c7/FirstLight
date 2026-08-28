import SwiftUI

// Shared SwiftUI building blocks for the three windows. The windows stay
// NSWindowController shells (menu-bar app lifecycle, status-item wiring);
// only their content is SwiftUI hosted via NSHostingController.

/// The windowBackground blur the AppKit version painted behind the content.
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .windowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

extension View {
    /// The rounded translucent card look (was a hand-configured NSBox).
    func cardStyle() -> some View {
        background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(nsColor: .separatorColor).opacity(0.45))
                )
        )
    }
}
