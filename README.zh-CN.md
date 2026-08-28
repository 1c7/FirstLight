# LightDose (light-for-better-sleep-mac)

[English](README.md)

一个很小的 macOS 菜单栏工具,实时读取 MacBook 内置的环境光传感器,追踪今天有没有晒够早晨的户外强光。

这是 Android/Flutter 项目 `../light-for-better-sleep` 的桌面端搭档:剂量公式、每日目标完全一致,1:1 照搬自 `lib/dose_calculator.dart`。用法也一样——把 MacBook 带到户外无遮挡的地方,盯着数字看。

个人工具,只给一个人用。没有做分发签名,不上 App Store,不建议分享或安装到别的机器上使用之前先看下面的注意事项。

## 界面和交互

菜单栏标题始终显示实时 lux 数值。**左键点击**打开(或关闭)一个正式的屏幕窗口,展示更大、更完整的信息:
- 当前 lux 读数
- 今日累计的"有效分钟数" vs 每日目标,用进度条展示
- 达标 / 未达标状态
- 光照有用时(≥ 500 lux):按当前亮度估算还需要多少分钟
- 光照太暗时(< 500 lux):显示"光线太暗,户外找个开阔地方",不显示倒计时

**右键点击**菜单栏图标弹出一个只有"退出"的小菜单。关闭窗口(红色按钮)只是把窗口藏起来——App 本身继续在菜单栏后台运行、继续累计今天的剂量。

进度数据存在本地:
`~/Library/Application Support/light-for-better-sleep-mac/daily_effective_minutes.json`,按日期分 key。不联网、不需要账号、无埋点。

## 传感器是怎么读的

MacBook 内置的环境光传感器在 macOS 上没有官方公开的框架可以读——和 iOS 情况一样。最初的计划是走苹果私有/未文档化的 `IOHIDEventSystemClient` HID 事件接口——和显示器亮度工具 [Lunar](https://github.com/alin23/Lunar) 用的是同一类技术。这条路先做了原型,能编译能链接,但在这台机器(2022 款 MacBook Air, M2)上,ALS 的 HID 服务始终没能通过这条路径返回事件。

后来 `Sources/LightDose/AmbientLightSensor.swift` 改成直接读传感器 IOService 节点上一个实时的 `CurrentLux` 属性(节点是 `AppleSPUVD6286`,`ioreg -p IOService -n als -l` 能看到它是 `als` 节点的下级),用的是**完全公开、有文档的** IOKit registry 调用(`IOServiceGetMatchingService` + `IORegistryEntryCreateCFProperty`)。整个 App 没有用到任何私有 API。

不过要说明:`AppleSPUVD6286` 和 `CurrentLux` 是这台 Mac 具体的驱动类名和一个"能读但没文档"的属性 key——都不是苹果承诺稳定的契约。以后 macOS 升级,或者换一台不同型号/芯片代际的 Mac,这个类名或属性都可能改名,直接导致读取失败。如果 App 显示"传感器不可用",重新跑一下 `ioreg -p IOService -n als -l`,找找 `als` 这条链路下面哪个节点现在还在暴露一个数值看起来合理的实时属性,然后照着改 `AmbientLightSensor.swift`。

## 剂量算法(必须和 Flutter 那边保持一致)

照搬自 `lib/dose_calculator.dart`:

- `weight(lux) = lux / (lux + 100)`(lux > 0 时,否则为 0;100 lux 是已发表的 ED50 半饱和锚点)
- `targetEffectiveMinutes = 20 * weight(10000)` —— 固定的每日目标
- 每约 2 秒轮询一次,只要当前 lux ≥ 500(`uselessBelowLux`),就把 `weight(currentLux) * elapsedSeconds / 60` 加到今天的累计有效分钟数里
- `remainingRealMinutes = (target - accumulated) / weight(currentLux)`,只在 currentLux ≥ 500 时才有意义
- 累计值 ≥ 目标值时算达标

和 Flutter 版不同的是,这里没有显式的"开始/停止记录"按钮——只要 App 开着、光照有用,就一直在累计,因为这本来就是设计给"站在户外、笔记本开着"这种前台场景用的工具。

## 编译 / 运行 / 安装

需要 Xcode Command Line Tools(用 Swift Package Manager,不需要 Xcode 工程)。

```sh
# 第一次构建，或每次改完代码后：编译 + 打包 + ad-hoc 签名
./Packaging/build.sh

# 运行
open LightDose.app
```

`Packaging/build.sh` 会跑 `swift build -c release`,把编译产物和 `Packaging/Info.plist` 组装成 `LightDose.app`,然后 ad-hoc 签名(`codesign --force --deep --sign -`),这样 Gatekeeper 才不会挡着不让在这台机器上打开。没有做公证(notarization)——反正这个 App 永远不会离开这台 Mac。

这个 App 故意**不带任何 sandbox entitlement** 构建。它需要在非沙盒环境下运行才能读到 IOKit 传感器属性;如果以后加了 entitlements 文件(比如从某个开了 App Sandbox 的 Xcode 模板带过来的),传感器读取可能会悄悄失效。

退出方法:右键点菜单栏的 lux 数字,选"退出"。

### 开机自启动(可选,目前没做)

为了保持简单,没做开机自启动。想要的话,现代 API 是 `SMAppService.mainApp.register()`(macOS 13+),需要在 `AppDelegate.swift` 里加几行代码、菜单里加个勾选项——目前没接。

## 项目结构

```
Package.swift
Sources/LightDose/
  main.swift                 -- NSApplication 启动入口
  AppDelegate.swift           -- NSStatusItem、点击分发逻辑、2秒轮询定时器
  MainWindowController.swift  -- 屏幕上的主窗口（左键点击打开）
  AmbientLightSensor.swift    -- IOKit lux 读取（注意事项见上文）
  DoseCalculator.swift        -- 照搬自 dose_calculator.dart
  DailyProgressStore.swift    -- 本地 JSON 持久化，按日期分 key
Packaging/
  Info.plist
  build.sh
```
