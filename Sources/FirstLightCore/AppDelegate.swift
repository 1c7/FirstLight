import AppKit
import Foundation

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let store = DailyProgressStore()
    private var mainWindowController: MainWindowController?
    private var settingsWindowController: SettingsWindowController?
    private var debugWindowController: DebugWindowController?
    private var debugSimulation: DebugSimulation?

    private var lastTickDate: Date?
    private var lastLux: Double?
    private var accumulatedMinutes: Double = 0
    private var currentDayKey: String = DailyProgressStore.dateKey(Date())

    private let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.usesGroupingSeparator = true
        return f
    }()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only app: no Dock icon, no app switcher entry.
        NSApp.setActivationPolicy(.accessory)

        accumulatedMinutes = store.minutes(for: Date())

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        numberFormatter.locale = L10n.locale
        statusItem.button?.title = "-- lux"
        // No fixed `.menu` here on purpose -- left-click opens the main
        // window, right-click shows secondary actions. See
        // statusItemClicked(_:).
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemLocaleDidChange),
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil
        )

        // Polling is simple and robust for a foreground-use tool; no need
        // for a raw HID event-callback stream. 0.25s matches the fastest
        // real update interval observed empirically by probing
        // CurrentLux at ~2ms resolution (min ~0.2s between genuine
        // value changes) -- polling faster than that just re-reads the
        // same cached value.
        tick() // populate immediately instead of waiting 0.25s for the first read
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }

        // Dev shortcut: `FirstLight --window` opens the main window right
        // away, so UI iteration doesn't need a status-item click each launch.
        if CommandLine.arguments.contains("--window") {
            DispatchQueue.main.async { [weak self] in self?.toggleMainWindow() }
        }
    }

    private func tick() {
        let now = Date()

        // Simulated values are display-only. In particular, never let a
        // debug scenario alter the persisted daily progress.
        if let simulation = debugSimulation {
            lastTickDate = nil
            lastLux = simulation.lux
            updateDisplayedState(
                lux: simulation.lux,
                accumulatedMinutes: simulation.accumulatedMinutes
            )
            return
        }

        // Roll over to a fresh day if the calendar date has changed while
        // the app kept running.
        let todayKey = DailyProgressStore.dateKey(now)
        if todayKey != currentDayKey {
            currentDayKey = todayKey
            accumulatedMinutes = store.minutes(for: now)
            lastTickDate = nil
        }

        guard let lux = AmbientLightSensor.readLux() else {
            statusItem.button?.title = L10n.text("传感器不可用", "Sensor unavailable")
            lastLux = nil
            lastTickDate = nil
            mainWindowController?.update(lux: nil, accumulatedMinutes: accumulatedMinutes, formatter: numberFormatter)
            return
        }

        // Accumulate effective minutes since the previous tick, only
        // while light is actually useful. Cap the interval so a sleep/
        // wake gap or a stalled timer doesn't get counted as one huge
        // sample (mirrors the 10s cap in the Flutter reference app).
        if let last = lastTickDate {
            let elapsed = min(now.timeIntervalSince(last), 10.0)
            if elapsed > 0 && DoseCalculator.isCurrentLightUseful(lux) {
                let delta = DoseCalculator.effectiveMinutes(forLux: lux, elapsedSeconds: elapsed)
                if delta > 0 {
                    accumulatedMinutes = store.addEffectiveMinutes(delta, for: now)
                }
            }
        }
        lastTickDate = now
        lastLux = lux

        updateUI(lux: lux)
    }

    private func updateUI(lux: Double) {
        updateDisplayedState(lux: lux, accumulatedMinutes: accumulatedMinutes)
    }

    private func updateDisplayedState(lux: Double?, accumulatedMinutes: Double) {
        let debugPrefix = debugSimulation == nil ? "" : L10n.text("模拟 · ", "SIM · ")
        mainWindowController?.setDebugSimulationActive(debugSimulation != nil)
        guard let lux else {
            statusItem.button?.title = debugPrefix + L10n.text("传感器不可用", "Sensor unavailable")
            mainWindowController?.update(
                lux: nil, accumulatedMinutes: accumulatedMinutes, formatter: numberFormatter)
            return
        }
        let luxRounded = numberFormatter.string(from: NSNumber(value: lux)) ?? "\(Int(lux))"
        statusItem.button?.title = "\(debugPrefix)\(luxRounded) lux"
        mainWindowController?.update(lux: lux, accumulatedMinutes: accumulatedMinutes, formatter: numberFormatter)
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggleMainWindow()
        }
    }

    // Right-click exposes secondary actions. Left-click never goes through
    // NSMenu, which keeps the primary interaction as a one-click window toggle.
    private func showContextMenu() {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(
            title: L10n.text("设置…", "Settings…"), action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        let debugItem = NSMenuItem(
            title: L10n.text("调试状态…", "Debug States…"), action: #selector(showDebug), keyEquivalent: "d")
        debugItem.target = self
        menu.addItem(debugItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(
            title: L10n.text("退出 FirstLight", "Quit FirstLight"),
            action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func toggleMainWindow() {
        let controller = mainWindowController ?? {
            let c = MainWindowController()
            c.onOpenSettings = { [weak self] in self?.showSettings() }
            c.onOpenDebug = { [weak self] in self?.showDebug() }
            mainWindowController = c
            return c
        }()
        guard let window = controller.window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            controller.setDebugSimulationActive(debugSimulation != nil)
            if let simulation = debugSimulation {
                controller.update(
                    lux: simulation.lux,
                    accumulatedMinutes: simulation.accumulatedMinutes,
                    formatter: numberFormatter
                )
            } else {
                controller.update(lux: lastLux, accumulatedMinutes: accumulatedMinutes, formatter: numberFormatter)
            }
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    // Accessory (menu-bar-only) app: closing the main window must not
    // quit the background process -- the status item needs to keep
    // polling and accumulating dose even with no window open.
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @objc private func showSettings() {
        let controller = settingsWindowController ?? {
            let c = SettingsWindowController()
            c.onLanguageChange = { [weak self] in self?.languageDidChange() }
            settingsWindowController = c
            return c
        }()
        NSApp.activate(ignoringOtherApps: true)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func showDebug() {
        let controller = debugWindowController ?? {
            let c = DebugWindowController()
            c.onSimulationChange = { [weak self] simulation in
                self?.debugSimulation = simulation
                self?.tick()
            }
            c.diagnosticsProvider = { AmbientLightSensor.diagnosticReport() }
            debugWindowController = c
            return c
        }()
        controller.refreshDiagnostics()
        NSApp.activate(ignoringOtherApps: true)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    private func languageDidChange() {
        numberFormatter.locale = L10n.locale
        mainWindowController?.localize()
        settingsWindowController?.localize()
        debugWindowController?.localize()
        tick()
    }

    @objc private func systemLocaleDidChange() {
        guard L10n.language == .system else { return }
        languageDidChange()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
