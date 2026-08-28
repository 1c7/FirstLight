# FirstLight

[中文说明](app/doc/README.zh-CN.md)

A tiny macOS menu bar app for people correcting a delayed sleep phase (going to bed and waking up very late) by getting bright light shortly after waking.

It reads your MacBook's built-in light sensor in real time and calculates whether today's light exposure has been strong enough, for long enough, to reset your circadian rhythm — so you don't have to guess or do the math yourself.

## Screenshots

<p align="center">
  <img src="app/doc/img/en-1.jpg" width="30%" alt="Light Progress" />
  <img src="app/doc/img/en-2.jpg" width="30%" alt="Live Illuminance" />
  <img src="app/doc/img/en-3.jpg" width="30%" alt="Why Light Matters" />
</p>

## Install

1. [Download FirstLight.dmg](https://github.com/1c7/FirstLight/releases/latest)
2. Open it, drag `FirstLight.app` into the `Applications` shortcut.
3. **First launch only**: If macOS displays "cannot verify the developer", right-click the app and choose **Open** once to bypass Gatekeeper.

## Usage

- **Left-click** the lux reading in the menu bar to open the main dashboard.
- **Right-click** for Settings, Debug States, or Quit.
- Supports both English and Simplified Chinese (follows system language by default).

## Compatibility

Requires **macOS 13 or later** on a Mac with a readable built-in ambient-light sensor.

**Confirmed working configuration:**
- MacBook Air (M2, 2022), model identifier `Mac14,2`

*Sensor access relies on the readable but undocumented `CurrentLux` IOKit property. If you test FirstLight on other Mac models, please feel free to report your results! If the sensor is unavailable on your device, use **Debug States → Copy Compatibility Diagnostics** and submit an issue.*

## Architecture & Docs

Detailed design and technical documentation are available in [`app/doc/`](app/doc/):
- [Competitor Research](app/doc/0-同类竞品调研.md)
- [Sensor Reading Principle](app/doc/1-传感器读取原理.md)
- [Light Dose Formula](app/doc/2-剂量计算公式.md)
- [Architecture & Build Guide](app/doc/3-项目结构与开发说明.md)
- [Localization & UI Architecture](app/doc/4-本地化与界面架构.md)

## License

FirstLight is open-sourced under the [MIT License](app/LICENSE).

