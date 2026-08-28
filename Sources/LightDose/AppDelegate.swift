import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let store = DailyProgressStore()

    // Menu items we update in place on every tick.
    private let luxItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let progressItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let statusLineItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let adviceItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")

    private var lastTickDate: Date?
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

        let menu = NSMenu()
        for item in [luxItem, progressItem, statusLineItem, adviceItem] {
            item.isEnabled = false
            menu.addItem(item)
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        for item in menu.items {
            item.target = self
        }
        statusItem.menu = menu

        // Polling is simple and robust for a foreground-use tool; no need
        // for a raw HID event-callback stream.
        tick() // populate immediately instead of waiting 2s for the first read
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
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
            luxItem.title = "无法读取光线传感器"
            progressItem.title = ""
            statusLineItem.title = ""
            adviceItem.title = ""
            lastTickDate = nil
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

        updateUI(lux: lux)
    }

    private func updateUI(lux: Double) {
        let luxRounded = numberFormatter.string(from: NSNumber(value: lux)) ?? "\(Int(lux))"
        statusItem.button?.title = "\(luxRounded) lux"

        luxItem.title = "当前光照：\(luxRounded) lux"

        let target = DoseCalculator.targetEffectiveMinutes
        let acc = accumulatedMinutes
        progressItem.title = String(format: "今日有效分钟：%.1f / %.1f 分钟", acc, target)

        let achieved = DoseCalculator.isAchieved(acc)
        statusLineItem.title = achieved ? "今日目标已达成 ✓" : "尚未达标"

        if achieved {
            adviceItem.title = "今天的晨光已经晒够啦"
        } else if DoseCalculator.isCurrentLightUseful(lux) {
            if let remaining = DoseCalculator.remainingRealMinutes(currentLux: lux, accumulatedEffectiveMinutes: acc) {
                adviceItem.title = String(format: "按当前光照，还需约 %.0f 分钟", remaining.rounded(.up))
            } else {
                adviceItem.title = ""
            }
        } else {
            adviceItem.title = "光线太暗,户外找个开阔地方"
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
