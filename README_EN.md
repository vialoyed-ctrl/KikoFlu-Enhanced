# KikoFlu Enhanced

[简体中文](README.md) · [日本語](README_JA.md)

A Kikoeru audio and video client with background playback, subtitles, offline downloads, and audio effects.

[Download](https://github.com/vialoyed-ctrl/KikoFlu-Enhanced/releases/latest) · [Issues](https://github.com/vialoyed-ctrl/KikoFlu-Enhanced/issues)

## Features

- Audio and video playback, playback speed, background audio, and saved progress.
- Adjustable equalizer and stereo expansion.
- Subtitle import, translation, timing adjustment, and library management.
- Seek by time or subtitle segment, with separate forward and backward settings.
- Fullscreen video gestures for seeking, brightness, and volume.
- Home search with space-separated keywords, tag search, tag copying, and history.
- Custom servers, multiple accounts, offline downloads, and cache management.

## Build

Flutter 3.44.1+ and Dart 3.12.1+.

```sh
git clone https://github.com/vialoyed-ctrl/KikoFlu-Enhanced.git
cd KikoFlu-Enhanced
flutter pub get
flutter build apk --release --target-platform android-arm64
```

## Credits and License

Based on [pa-jesusf/KikoFlu](https://github.com/pa-jesusf/KikoFlu) 3.8.2. Original author and contributor copyrights are retained under [GPL-3.0](LICENSE). Third-party licenses are in `third_party/`.

2026-10-11: Added audio effects, media-key mapping, and fullscreen video gestures; updated subtitle storage and search, and fixed refresh after disconnection.
