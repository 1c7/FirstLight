# LightDose (light-for-better-sleep-mac)

A tiny macOS menu bar app that reads the MacBook's built-in ambient
light sensor in real time and tracks whether you've gotten enough
outdoor morning light exposure today.

This is the desktop companion to the Android/Flutter app at
`../light-for-better-sleep`: same dose math, same daily target, ported
1:1 from `lib/dose_calculator.dart`. It's meant to be used the same
way -- carry the MacBook outdoors to an unobstructed spot and watch the
number in the menu bar.

Personal tool for one user. Not signed for distribution, not on the App
Store, not intended to be shared or installed on another machine
without re-reading the caveats below.

## What it shows

Click the lux number in the menu bar to see:
- current lux reading
- today's accumulated "effective minutes" vs. the daily target
- achieved / not-achieved
- if light is currently useful (>= 500 lux): an estimate of how many
  more minutes you need at the current brightness
- if light is too dim (< 500 lux): "光线太暗,户外找个开阔地方" instead
  of a countdown

Progress is stored locally in
`~/Library/Application Support/light-for-better-sleep-mac/daily_effective_minutes.json`,
keyed by date. No network calls, no accounts, no telemetry.

## How the sensor reading works

The built-in ambient light sensor has no public Apple framework for
reading lux on macOS (same situation as iOS). The original plan was to
go through Apple's private/undocumented `IOHIDEventSystemClient` HID
event API -- the same class of technique the display-brightness tool
[Lunar](https://github.com/alin23/Lunar) uses. That was prototyped
first and it does link and run, but on this hardware
(2022 MacBook Air, M2) the ALS's HID service never returned an event
through that path.

Instead, `Sources/LightDose/AmbientLightSensor.swift` reads a live
`CurrentLux` property directly off the sensor's IOService node
(`AppleSPUVD6286`, a descendant of the `als` node visible via
`ioreg -p IOService -n als -l`), using only fully public, documented
IOKit registry calls (`IOServiceGetMatchingService` +
`IORegistryEntryCreateCFProperty`). No private API is used anywhere in
this app.

That said: `AppleSPUVD6286` and `CurrentLux` are this Mac's specific
driver class name and an undocumented (if publicly-readable) property
key -- neither is an Apple-guaranteed stable contract. A future macOS
update, or a different Mac model/chip generation, could rename the
class or the property and break sensor reads outright. If the app ever
shows "传感器不可用" ("sensor unavailable"), re-run
`ioreg -p IOService -n als -l` and look for whichever node under the
`als` chain currently exposes a live-looking numeric lux property, then
update `AmbientLightSensor.swift` accordingly.

## Dose math (must match the Flutter app)

Ported from `lib/dose_calculator.dart`:

- `weight(lux) = lux / (lux + 100)` for lux > 0, else 0 (100 lux =
  published ED50 half-saturation anchor)
- `targetEffectiveMinutes = 20 * weight(10000)` -- fixed daily target
- every ~2s poll tick, add `weight(currentLux) * elapsedSeconds / 60`
  to today's accumulated effective minutes, but only while currentLux
  is >= 500 (`uselessBelowLux`)
- `remainingRealMinutes = (target - accumulated) / weight(currentLux)`,
  only meaningful when currentLux >= 500
- achieved when `accumulated >= target`

Unlike the Flutter app, there's no explicit "start/stop session"
button here -- accumulation just runs continuously while the app is
open and light is useful, since this is meant to be a foreground tool
you glance at while standing outside with the laptop open.

## Build / run / install

Requires Xcode Command Line Tools (Swift Package Manager, no Xcode
project needed).

```sh
# one-time or after any code change: build + package + ad-hoc sign
./Packaging/build.sh

# run it
open LightDose.app
```

`Packaging/build.sh` runs `swift build -c release`, assembles
`LightDose.app` (binary + `Packaging/Info.plist`), and ad-hoc signs it
(`codesign --force --deep --sign -`) so Gatekeeper doesn't block
launching it on this machine. No notarization -- it never leaves this
Mac.

The app is deliberately built **without any sandbox entitlements**. It
needs to run unsandboxed to read the IOKit sensor property; if you ever
add an entitlements file (e.g. from an Xcode template with App Sandbox
turned on), sensor access may silently break.

To quit: click the lux number in the menu bar, then "退出".

### Login item (optional, not set up)

Auto-launch at login was left out to keep this simple. If you want it,
the modern API is `SMAppService.mainApp.register()` (macOS 13+, add a
few lines to `AppDelegate.swift` and a checkbox in the menu) -- not
wired up here.

## Project layout

```
Package.swift
Sources/LightDose/
  main.swift               -- NSApplication bootstrap
  AppDelegate.swift         -- NSStatusItem, menu, 2s polling timer
  AmbientLightSensor.swift  -- IOKit lux reading (see caveats above)
  DoseCalculator.swift      -- ported from dose_calculator.dart
  DailyProgressStore.swift  -- local JSON persistence, keyed by date
Packaging/
  Info.plist
  build.sh
```
