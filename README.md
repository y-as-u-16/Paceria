# Pace

> 毎日やらなくていい。自分で決めたペースを守れているかだけを見る。

読書と運動の記録アプリ。「何日連続で続いたか」ではなく、**自分で決めた週/月の
ペースを満たせたか**を可視化する。水曜に何もしなくても、それは失敗ではない。

[![CI](https://github.com/y-as-u-16/Pace/actions/workflows/ci.yml/badge.svg)](https://github.com/y-as-u-16/Pace/actions/workflows/ci.yml)
[![Guards](https://github.com/y-as-u-16/Pace/actions/workflows/guards.yml/badge.svg)](https://github.com/y-as-u-16/Pace/actions/workflows/guards.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Status

**Early development.** 設計は完了して文書化済み。実装はこれから。
アプリはまだ何もしない。

| Area | State |
|---|---|
| プロダクト・アーキテクチャ設計 | 文書化済み（[docs/](docs/)） |
| CI（ビルド・テスト） | 稼働中 |
| Guards（規約・機密情報検査） | 稼働中 |
| CD（TestFlight 配信） | 設定済み・未配信 |
| Domain / Data / Feature 層 | 未実装 |

---

## Concept

一般的な習慣トラッカーは「連続日数」を主役にする。1日空けると壊れる。

Pace は違う指標を使う。

```
目標: 運動 週2回

月   火   水   木   金   土   日
-    ✓    -    -    ✓    -    -

→ 今週は達成
→ 直近8週のうち6週で達成
```

「知性」と「身体」という2軸の自己成長を、無理のないペースで積み上げる。

### 設計上の約束

- 連続日数（Daily Streak）を主役にしない
- 休むことを失敗として表示しない
- 他人と比較しない（アプリ内 SNS は実装しない）
- 記録は10秒以内

---

## Documentation

| Document | Contents |
|---|---|
| [01_PRODUCT_REQUIREMENTS.md](docs/01_PRODUCT_REQUIREMENTS.md) | コンセプト・競合整理・独自性・MVP・画面構成 |
| [02_ARCHITECTURE.md](docs/02_ARCHITECTURE.md) | Feature-based Clean Architecture・MVVM・DI・依存方向 |
| [03_DOMAIN_AND_DATA.md](docs/03_DOMAIN_AND_DATA.md) | ドメインモデル・継続判定・SwiftData・Repository API |
| [04_MVP_AND_ROADMAP.md](docs/04_MVP_AND_ROADMAP.md) | MVP スコープ・実装順序・テスト戦略・リリース基準 |

---

## Tech Stack

```
Swift / SwiftUI / SwiftData (local-first)
Feature-based Pragmatic Clean Architecture + MVVM
```

- 依存方向は `Presentation → Domain ← Data`
- Domain は SwiftUI / SwiftData を import しない
- SwiftData の `@Model` と Domain の `struct` は Mapper で分離
- DI ライブラリは使わず `AppContainer` で組み立てる

詳細は [docs/02_ARCHITECTURE.md](docs/02_ARCHITECTURE.md) を参照。

---

## Build

```bash
git clone https://github.com/y-as-u-16/Pace.git
cd Pace
open Pace.xcodeproj
```

`DEVELOPMENT_TEAM` は空にして公開している。シミュレータ向けのビルドと
テストは署名なしで実行できる。実機ビルドには Xcode の Signing & Capabilities
で自分の Team を選ぶ。

### Test

```bash
xcodebuild test \
  -project Pace.xcodeproj \
  -scheme Pace \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:PaceTests
```

### Guards

CI と同じ検査をローカルで実行できる。

```bash
./scripts/check-architecture.sh   # 依存方向の検査
./scripts/check-no-secrets.sh     # 機密情報の検査
```

---

## CI / CD

| Workflow | Trigger | Runner | Does |
|---|---|---|---|
| [CI](.github/workflows/ci.yml) | PR / push to main | macos-26 | ビルドとユニットテスト |
| [Guards](.github/workflows/guards.yml) | PR / push to main | ubuntu-latest | 依存方向と機密情報の検査 |
| [CD](.github/workflows/cd.yml) | push to main | macos-26 | TestFlight へ配信 |

Guards が Linux で走るのは、Xcode 不要のテキスト検査だから。macOS ランナーは
無料枠を10倍消費する。

署名は [fastlane match](https://docs.fastlane.tools/actions/match/) で
private な証明書リポジトリから取得する。Cookory / BaseMatch と同じ
リポジトリを共有している。

---

## License

[MIT](LICENSE)
