# KikoFlu Enhanced

基于 [pa-jesusf/KikoFlu](https://github.com/pa-jesusf/KikoFlu) 3.8.2 的独立修改版。
原项目作者及贡献者保留其版权。本项目不是原作者的官方版本，也不代表原作者背书。

## 下载修改版

[Android arm64 APK — 3.8.2+2006](https://github.com/vialoyed-ctrl/KikoFlu-Enhanced/releases/download/v3.8.2-enhanced.2006/KikoFlu-Enhanced-3.8.2-2006-arm64.apk)

包名 `com.meteor.kikoeruflutter.dspcheck`，应用名 **KikoFlu DSP**。与已安装的 DSP 测试版一致，可覆盖安装；与原版包名不同。此包使用开发签名，尚未配置正式发行签名。

## 修改内容（2026-10-11）

- Android 音效设置：均衡器、立体声扩展及可调整参数。
- 媒体上一首/下一首按键可映射为独立时长快退/快进，或上一段/下一段字幕；界面切歌按钮保留原功能。
- 视频播放与现有播放器融合，支持全屏、字幕和全屏双击、亮度、音量、进度手势。
- 字幕存储与迁移支持。
- 搜索集中到主页入口：空格分隔关键词、标签搜索及历史记录；移除底部搜索页和添加条件按钮。
- 网络断连恢复和刷新修复，以及相关测试与死代码清理。

## 许可证与来源

继续使用 [GNU GPL v3](LICENSE)。保留上游版权、许可证及第三方软件的许可证。
发布修改版时需遵守 GPL，包括提供对应源码及修改说明。
音效算法实现不来自 Poweramp 源码，不宣称与其效果完全相同。

## 构建

需要 Flutter 3.44.1+、Dart 3.12.1+，Android 构建需要兼容的 JDK/SDK。

```sh
flutter pub get
flutter build apk --release --target-platform android-arm64
```

`third_party/` 中的本地插件源码必须保留。SDK 路径和签名配置请在本机配置，仓库不包含签名密钥。
如需沿用测试版包名，可在 Android Gradle 构建时传入 `-PkikoApplicationId=com.meteor.kikoeruflutter.dspcheck`。
Android 未配置 release keystore 时现有构建脚本使用 debug 签名；正式分发请配置自己的签名。
修改版 Android 安装包见 [Releases](https://github.com/vialoyed-ctrl/KikoFlu-Enhanced/releases/latest)。仓库不包含个人账号配置、媒体、字幕库、截图或设备日志。

## 验证记录

发布副本由本地 3.8.2+2006 源码整理。此前 44 项搜索与连接专项测试通过；全量测试存在 34 项可在修改前基线复现的失败。
此次发布只整理文件与说明，未改动播放器或搜索行为。

---

以下保留上游功能说明。修改版下载和源码链接已改为本仓库；上游反馈链接仍指向原作者项目。当前修改版 Release 仅提供 Android arm64 安装包，其他平台介绍仅描述上游能力。

<div align="center">
  <img src="assets/icons/app_icon_opaque.png" alt="KikoFlu" width="120" height="120">

  # KikoFlu

  [English](README_EN.md) | [日本語](README_JA.md) | 简体中文
  
  一个跨平台同人音声客户端，支持连接 Kikoeru 自建服务器或在线服务

  [![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)](#)
  [![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)


</div>

<div align="center">
  <img src="screenshots/8.png" width="900" alt="KikoFlu 截图">
</div>

## 特性

### 🎵 媒体播放
- 后台播放与自动缓存机制
- 迷你播放器、播放项目与播放进度持久化
- 倍速播放
- 单曲循环、列表循环、随机播放
- 全局音频增益（支持衰减与增强）
- 音频触感反馈(Beta)：移动端根据声音特征控制设备振动
- 多媒体支持：音频、视频、文本、图片、PDF 等
- 支持整个作品或选择性下载，并发下载管理
- 离线下载搜索与排序
- 本地导入作品元数据识别

### 📝 字幕系统
- 自动字幕加载
- 字幕导入、编辑、调轴
- 支持 `.vtt`、`.srt`、`.lrc`、`.txt`、`.ass`、`.ssa`、`.sub`、`.idx`、`.sbv`、`.dfxp`、`.ttml`
- 字幕翻译（播放时实时翻译歌词/台词）
- 播放器内翻译当前播放字幕，完成后立即显示并保存
- 歌词/字幕全屏显示
- 字幕库（SQLite 索引，快速检索）
- 支持保存目录修改，跨硬盘拷贝

### 🎨 界面
- 全平台支持（Android / iOS / Windows / macOS / Linux）
- Material Design 3 设计规范
- 液态玻璃导航栏与迷你播放器；Apple 系 26+ 平台默认开启，其他平台提供兼容模式
- 横屏模式支持
- 明暗主题自适应
- 标题、文件目录、文本文件翻译
- 标签自动翻译（中/英/日）
- 防社死模式
- 评分系统
- 推荐作品功能

### 🔍 搜索
- 高级搜索，支持多标签 / 排除标签
- 多维度筛选（标签、评分、发售日期等）
- 完整作品信息展示

### 🌐 国际化
- 简体中文 / 繁體中文 / English / 日本語 / Русский
- 多形式、多语言翻译支持

### ⚙️ 设置
- 多账户支持
- 自定义服务器地址（[使用指南](https://github.com/pa-jesusf/KikoFlu/wiki/%E4%BD%BF%E7%94%A8%E8%87%AA%E5%BB%BA%E5%90%8E%E7%AB%AF%E6%9C%8D%E5%8A%A1%E5%99%A8)），可测试连接延迟
- 自定义缓存大小限制与清理策略
- 主题模式、配色方案自由选择
- 翻译目标语言可单独设置，LLM 模式支持自定义目标语言
- 字幕库优先级、音频格式偏好、预加载与音频增益等播放设置
- 丰富的界面自定义选项
- 应用内日志系统（支持导出）
- 更新检查

### 📝 悬浮字幕
- Android、iOS、Windows、macOS、Linux 均支持悬浮字幕
- Android 支持锁定 / 解锁与触控穿透，桌面端支持点击穿透
- iOS 使用系统画中画显示悬浮字幕

---

## 下载

前往 [Releases](https://github.com/vialoyed-ctrl/KikoFlu-Enhanced/releases/latest) 下载最新版本。

支持平台：Android（universal / arm64-v8a）、iOS（未签名 IPA）、Windows（安装包 / 便携版）、macOS（DMG）、Linux（x64 / arm64）


## 源码构建

### 环境要求
- Flutter SDK 3.44.1+
- Dart SDK 3.12.1+

```bash
git clone https://github.com/vialoyed-ctrl/KikoFlu-Enhanced.git
cd KikoFlu-Enhanced
flutter pub get
```

### 构建命令

| 平台 | 命令 |
|------|------|
| Android | `flutter build apk --release --split-per-abi` |
| Windows | `flutter build windows --release` |
| macOS | `flutter build macos --release` |
| Linux | `flutter build linux --release` |
| iOS | `./build_ios_xcode.sh` |

---

## 相关项目

- [Kikoeru](https://github.com/Number178/kikoeru-express) — 自建后端服务器
- [asmr.one](https://www.asmr.one) — 在线服务

## 开源协议

[GPL-3.0 License](LICENSE)

## 联系方式

- **问题反馈**：[Issues](https://github.com/pa-jesusf/KikoFlu/issues)
- **交流群组**：[Telegram](https://t.me/+PrkiN-pZrXs4ZTU1)

---

<div align="center">

  **如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！**

</div>
