# 产品名称 "醒后见光"

[English](README.md)

## 对你有什么价值？
如果你晚睡晚起，想改成早睡早起，方法是醒后尽快去户外见光很重要。可以调整你的生物钟。

本软件是 macOS App，读取 MacBook 内置的光线传感器，告诉你当前是多少 Lux。


## 截图演示（待补充）


## 安装

1. [下载 FirstLight.dmg](https://github.com/1c7/light-for-better-sleep-mac/releases/latest)
2. 打开磁盘映像，把 `FirstLight.app` 拖进 `Applications` 快捷方式
3. 只有第一次打开会提示"无法验证开发者"——右键点 App 选"打开"绕过一次就好，以后正常双击打开

左键点菜单栏的 lux 数字打开主窗口；右键点退出。

不上 App Store、没做公证——原因见 [doc/3](doc/3-项目结构与开发说明.md)。
想自己从源码编译？也在 [doc/3](doc/3-项目结构与开发说明.md) 里。

## 文档

- [doc/0-同类竞品调研.md](doc/0-同类竞品调研.md) —— 市面上有没有类似的 App
- [doc/1-传感器读取原理.md](doc/1-传感器读取原理.md) —— lux 是怎么读出来的，坏了怎么修
- [doc/2-剂量计算公式.md](doc/2-剂量计算公式.md) —— 剂量公式
- [doc/3-项目结构与开发说明.md](doc/3-项目结构与开发说明.md) —— 项目结构、打包细节、为什么不能上 App Sandbox
