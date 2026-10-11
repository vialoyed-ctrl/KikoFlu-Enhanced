# KikoFlu Enhanced

[English](README_EN.md) · [日本語](README_JA.md)

Kikoeru 音视频客户端，支持后台播放、字幕、离线下载和音效调节。

[下载安装](https://github.com/vialoyed-ctrl/KikoFlu-Enhanced/releases/latest) · [问题反馈](https://github.com/vialoyed-ctrl/KikoFlu-Enhanced/issues)

## 功能

- 音频与视频播放，支持倍速、后台播放和进度保存。
- 均衡器与立体声扩展，参数可自行调整。
- 字幕导入、翻译、调轴及字幕库管理。
- 按时间或字幕段落快进、快退，两个方向分别设置。
- 视频全屏手势：双击跳转、滑动调亮度和音量、横向拖动进度。
- 主页统一搜索，支持空格分隔关键词、标签搜索、复制标签和搜索历史。
- 自定义服务器、多账户、离线下载和缓存管理。

## 构建

Flutter 3.44.1+、Dart 3.12.1+。

```sh
git clone https://github.com/vialoyed-ctrl/KikoFlu-Enhanced.git
cd KikoFlu-Enhanced
flutter pub get
flutter build apk --release --target-platform android-arm64
```

## 来源与许可证

基于 [pa-jesusf/KikoFlu](https://github.com/pa-jesusf/KikoFlu) 3.8.2，保留原作者及贡献者版权，采用 [GPL-3.0](LICENSE)。第三方许可证见 `third_party/`。

2026-10-11：新增音效调节、媒体按键映射和视频全屏手势；调整字幕存储与搜索入口，修复断连后刷新。
