# 产品名称 "醒后见光"

[English](README.md)

## 对你有什么价值？
如果你经常晚睡晚起，希望调整成早睡早起，那么醒后尽快去户外见光很重要。可以调整你的生物钟。

本软件是一个 macOS App，实时读取 MacBook 内置的光线传感器，告诉你当前是多少 Lux。

## 截图演示


## 安装

需要 Xcode Command Line Tools。

```sh
git clone <this repo>
cd light-for-better-sleep-mac
./Packaging/build.sh
open LightDose.app
```

左键点菜单栏的 lux 数字打开主窗口；右键点退出。

## 文档

- [doc/0-同类竞品调研.md](doc/0-同类竞品调研.md) —— 市面上有没有类似的 App
- [doc/1-传感器读取原理.md](doc/1-传感器读取原理.md) —— lux 是怎么读出来的，坏了怎么修
- [doc/2-剂量计算公式.md](doc/2-剂量计算公式.md) —— 剂量公式
- [doc/3-项目结构与开发说明.md](doc/3-项目结构与开发说明.md) —— 项目结构、打包细节、为什么不能上 App Sandbox
