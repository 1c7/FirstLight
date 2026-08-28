import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let store = DailyProgressStore()
    private var mainWindowController: MainWindowController?

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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only app: no Dock icon, no app switcher entry.
        NSApp.setActivationPolicy(.accessory)

        accumulatedMinutes = store.minutes(for: Date())

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "-- lux"
        // No fixed `.menu` here on purpose -- left-click opens the main
        // window, right-click shows a small quit-only menu. See
        // statusItemClicked(_:).
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

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
    }

    private func tick() {
        let now = Date()

        // Roll over to a fresh day if the calendar date has changed while
        // the app kept running.
        let todayKey = DailyProgressStore.dateKey(now)
        if todayKey != currentDayKey {
            currentDayKey = todayKey
            accumulatedMinutes = store.minutes(for: now)
            lastTickDate = nil
        }

        guard let lux = AmbientLightSensor.readLux() else {
            statusItem.button?.title = "传感器不可用"
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
        let luxRounded = numberFormatter.string(from: NSNumber(value: lux)) ?? "\(Int(lux))"
        statusItem.button?.title = "\(luxRounded) lux"
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

    // Right-click only: a plain quit item. Left-click never goes through
    // NSMenu at all, which is what lets a single click toggle the window
    // instead of always popping a dropdown.
    private func showContextMenu() {
        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func toggleMainWindow() {
        let controller = mainWindowController ?? {
            let c = MainWindowController()
            mainWindowController = c
            return c
        }()
        guard let window = controller.window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            controller.update(lux: lastLux, accumulatedMinutes: accumulatedMinutes, formatter: numberFormatter)
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    // Accessory (menu-bar-only) app: closing the main window must not
    // quit the background process -- the status item needs to keep
    // polling and accumulating dose even with no window open.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
