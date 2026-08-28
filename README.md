# FirstLight

[中文说明](README.zh-CN.md)

A tiny macOS menu bar app for people correcting a delayed sleep phase
(going to bed and waking up very late) by getting bright light shortly
after waking. It reads your MacBook's built-in light sensor in real
time and tells you whether today's light has been strong enough, for
long enough, to count -- so you don't have to guess or do the math
yourself.

![FirstLight app screenshot](doc/img/showcase.jpg)


## Install

1. [Download FirstLight.dmg](https://github.com/1c7/FirstLight/releases/latest)
2. Open it, drag `FirstLight.app` into the `Applications` shortcut
3. First launch only: macOS will say "cannot verify the developer" --
   right-click the app and choose **Open** once to get past it

Left-click the lux number in the menu bar to open the main window.
Right-click it for Settings, Debug States, or Quit. The app follows the
macOS language by default. Settings offers Follow System, Chinese, and English.

## Compatibility

FirstLight requires macOS 13 or later and a Mac with a readable built-in
ambient-light sensor. Confirmed working configuration:

- MacBook Air (M2, 2022), model identifier `Mac14,2`

Sensor access relies on the readable but undocumented `CurrentLux` IOKit
property. The app first checks the driver found on the tested Mac, then falls
back to discovering any IOKit service that exposes a numeric `CurrentLux`
value. Other models may work but have not yet been physically verified. If the
sensor is unavailable, open **Debug States → Copy Compatibility Diagnostics**
and include the copied report with an issue.
