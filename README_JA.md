# KikoFlu Enhanced

[简体中文](README.md) · [English](README_EN.md)

バックグラウンド再生、字幕、オフライン保存、音響調整に対応した Kikoeru 音声・動画クライアント。

[ダウンロード](https://github.com/vialoyed-ctrl/KikoFlu-Enhanced/releases/latest) · [不具合報告](https://github.com/vialoyed-ctrl/KikoFlu-Enhanced/issues)

## 機能

- 音声・動画再生、再生速度の変更、バックグラウンド再生、再生位置の保存。
- 調整可能なイコライザーとステレオ拡張。
- 字幕の読み込み、翻訳、タイミング調整、ライブラリ管理。
- 時間または字幕区間での早送り・巻き戻し。方向ごとに設定可能。
- 全画面動画のジェスチャー操作で再生位置、明るさ、音量を調整。
- ホームからの検索、スペース区切りのキーワード、タグ検索・コピー、検索履歴。
- カスタムサーバー、複数アカウント、オフライン保存、キャッシュ管理。

## ビルド

Flutter 3.44.1+、Dart 3.12.1+。

```sh
git clone https://github.com/vialoyed-ctrl/KikoFlu-Enhanced.git
cd KikoFlu-Enhanced
flutter pub get
flutter build apk --release --target-platform android-arm64
```

## 出典とライセンス

[pa-jesusf/KikoFlu](https://github.com/pa-jesusf/KikoFlu) 3.8.2 を基にしています。原作者と貢献者の著作権を保持し、[GPL-3.0](LICENSE) を適用します。第三者のライセンスは `third_party/` にあります。

2026-10-11：音響調整、メディアキー設定、全画面動画ジェスチャーを追加。字幕保存と検索を変更し、切断後の更新を修正。
