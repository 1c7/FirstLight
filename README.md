# LightDose (light-for-better-sleep-mac)

[中文说明](README.zh-CN.md)

A tiny macOS menu bar app for people correcting a delayed sleep phase
(going to bed and waking up very late) by getting bright light shortly
after waking. It reads your MacBook's built-in light sensor in real
time and tells you whether today's light has been strong enough, for
long enough, to count -- so you don't have to guess or do the math
yourself.

It's the desktop companion to the Android app at
[light-for-better-sleep](https://github.com/1c7/light-for-better-sleep):
same dose target, same math. Meant to be used the same way -- take the
MacBook outdoors to an unobstructed spot.

Personal tool, MIT licensed. Not on the App Store (see
[doc/3](doc/3-项目结构与开发说明.md) for why) -- build it yourself.

## Install

Requires Xcode Command Line Tools.

```sh
git clone <this repo>
cd light-for-better-sleep-mac
./Packaging/build.sh
open LightDose.app
```

Left-click the lux number in the menu bar to open the main window;
right-click it to quit.

## Docs

- [doc/0-同类竞品调研.md](doc/0-同类竞品调研.md) -- market survey of similar apps
- [doc/1-传感器读取原理.md](doc/1-传感器读取原理.md) -- how lux reading works, and what to do if it breaks
- [doc/2-剂量计算公式.md](doc/2-剂量计算公式.md) -- the dose formula
- [doc/3-项目结构与开发说明.md](doc/3-项目结构与开发说明.md) -- project layout, build internals, why no App Sandbox

(docs are Chinese-only for now)
