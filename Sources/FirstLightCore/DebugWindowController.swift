import AppKit
import SwiftUI

final class DebugWindowController: NSWindowController {
    var onSimulationChange: ((DebugSimulation?) -> Void)?
    var diagnosticsProvider: (() -> String)?

    private let model = DebugViewModel()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 470, height: 470),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.center()
        self.init(window: window)
        // Fixed-size windows: don't let the SwiftUI content drive sizing.
        let hosting = NSHostingController(rootView: DebugContentView(
            model: model,
            onChange: { [weak self] in self?.publishSimulation() },
            onCopy: { [weak self] in self?.copyDiagnostics() }
        ))
        hosting.sizingOptions = []
        contentViewController = hosting
        window.setContentSize(NSSize(width: 470, height: 470))
        localize()
    }

    func localize() {
        window?.title = L10n.text("调试状态", "Debug States")
        model.localeRevision += 1
        refreshDiagnostics()
    }

    func refreshDiagnostics() {
        model.diagnostics = diagnosticsProvider?() ?? ""
    }

    private func publishSimulation() {
        if model.preset == .custom {
            onSimulationChange?(DebugSimulation(
                lux: model.customLux,
                accumulatedMinutes: model.customMinutes
            ))
        } else {
            onSimulationChange?(model.preset.simulation)
        }
    }

    private func copyDiagnostics() {
        refreshDiagnostics()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(model.diagnostics, forType: .string)
    }
}

@MainActor
final class DebugViewModel: ObservableObject {
    @Published var preset = DebugPreset.live
    @Published var customLux = 2_000.0
    @Published var customMinutes = 5.0
    @Published var diagnostics = ""
    @Published var localeRevision = 0
}

struct DebugContentView: View {
    @ObservedObject var model: DebugViewModel
    var onChange: () -> Void
    var onCopy: () -> Void

    private var customEnabled: Bool { model.preset == .custom }

    var body: some View {
        let _ = model.localeRevision
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text("调试状态", "Debug States"))
                .font(.system(size: 24, weight: .bold))
            Text(L10n.text(
                "模拟状态仅影响显示，不会写入或覆盖真实的每日进度。",
                "Simulations only affect the display and never write to your real daily progress."
            ))
            .font(.system(size: 12))
            .foregroundColor(Color(nsColor: .secondaryLabelColor))
            presetRow.padding(.top, 12)
            header(L10n.text("自定义照度", "Custom Illuminance"),
                   value: String(format: "%.0f lux", model.customLux))
            Slider(value: $model.customLux, in: 0...20_000)
                .disabled(!customEnabled)
                .onChange(of: model.customLux) { _ in onChange() }
            header(L10n.text("自定义有效分钟", "Custom Effective Minutes"),
                   value: String(format: "%.1f %@", model.customMinutes, L10n.text("分钟", "min")))
            Slider(value: $model.customMinutes,
                   in: 0...(DoseCalculator.targetEffectiveMinutes * 1.25))
                .disabled(!customEnabled)
                .onChange(of: model.customMinutes) { _ in onChange() }
            Divider().padding(.vertical, 4)
            Text(model.diagnostics)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onCopy) {
                Label(L10n.text("复制兼容性诊断", "Copy Compatibility Diagnostics"),
                      systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var presetRow: some View {
        HStack {
            Text(L10n.text("场景", "Scenario"))
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Picker("", selection: $model.preset) {
                ForEach(DebugPreset.allCases, id: \.self) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .frame(minWidth: 150)
            .onChange(of: model.preset) { _ in onChange() }
        }
    }

    private func header(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(nsColor: customEnabled ? .labelColor : .tertiaryLabelColor))
            Spacer()
            Text(value)
                .font(.system(size: 12).monospacedDigit())
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
        }
    }
}

#Preview {
    let model = DebugViewModel()
    model.preset = .custom
    model.diagnostics = "AppleArm2022Arm\n\n--- lm7 (virtual) ---\n\"AmbientLightValue\" = 42"
    return DebugContentView(model: model, onChange: {}, onCopy: {})
        .frame(width: 470, height: 470)
}
