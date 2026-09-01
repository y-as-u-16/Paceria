# 05. UI Audit — Liquid Glass / HIG 適合調査

Issue #14 の調査記録と、それに基づく変更の記録。

環境: Xcode 26.6 / iOS Deployment Target 26.5（Liquid Glass API が利用可能）

---

## 1. 全体所見

現状は「旧来の SwiftUI で手堅く組まれた UI」であり、Liquid Glass を独自に模倣した箇所は**無い**。禁止事項に挙がっている以下は現時点で該当なし。

| 禁止事項 | 該当 |
|---|---|
| Content Layer への Liquid Glass 乱用 | なし（Glass API 未使用） |
| 全 Button の Glass 化 | なし |
| 標準 Navigation Bar / Tab Bar / Toolbar への Custom Background | なし |
| Gradient / Shadow / Blur の乱用 | なし |
| 固定 Font Size の乱用 | なし（semantic style のみ） |
| 独自 Material による Liquid Glass の模倣 | なし |

したがって本 Issue の作業は「独自実装の撤去」ではなく、**System が提供する新しい既定値を妨げている箇所の除去**と、**Functional Layer への標準 Glass の適用**が中心になる。

---

## 2. 画面別の現状

| 画面 | 構造 | Content Layer | 主な論点 |
|---|---|---|---|
| `RootView` | `TabView` + `Tab` 4つ | — | Tab Bar の最新挙動が未検討 |
| `HomeView` | `ScrollView` + 手組みカード | 進捗カード2枚 / Recent Wins | **カードの独自 Background** |
| `LibraryView` | `List` + Section | 蔵書一覧 | 標準どおり。問題なし |
| `BookDetailView` | `Form` | 詳細・評価・メモ | 標準どおり。評価は `.plain` Button |
| `ActivityView` | `List` | 運動履歴 | 標準どおり。アイコン幅が固定 |
| `AddMovementView` | `Form` + 横スクロールチップ | 入力 | **チップの独自 Background** |
| `AddBookView` | `Form` | 入力 | 標準どおり |
| `GoalSettingsView` | `Form` | 設定 | 標準どおり |
| `InsightsView` | `ScrollView` + 手組みカード | 達成履歴 | **カードの独自 Background** |
| `OnboardingView` | `ScrollView` + `safeAreaInset` | 説明・目標設定 | **`.background(.bar)` が Scroll Edge を妨げる可能性** |

---

## 3. 検出した差分

### 3-1. Content Layer の独自 Background（要判断）

`Color(.secondarySystemBackground)` を敷いた角丸カードが3箇所。

- `HomeView.swift:105` — Pace カード
- `HomeView.swift:142` — Recent Wins
- `InsightsView.swift:71` — 達成履歴カード

これらは Content Layer なので **Liquid Glass の対象外**（Issue §2）。ただし Issue §11 は「Visual Hierarchy は Typography / Spacing / Alignment / Contrast / Position で表現し、Card / Border / Background Color へ過度に依存しない」としている。

**判断**: カード自体は情報の区切りとして機能しており、乱用ではない。ただし `ScrollView` + 手組みカードより、`List` の `Section` を使うほうが System Metrics（Row Height / Section Spacing / Section Shape）に自動追従できる（Issue §12）。Home と Insights は List ベースへ寄せる余地がある。

### 3-2. Functional Layer への Glass 適用（未対応）

Issue §7 が挙げる `.buttonStyle(.glass)` / `.glassProminent` が未使用。

- `HomeView.swift:162` — Quick Add ボタン2つが `.borderedProminent`
- `OnboardingView.swift:30` — 開始ボタンが `.borderedProminent`

Quick Add は Content の上に浮く操作要素であり、Functional Layer に該当する。`.glassProminent` の検討対象。

### 3-3. 独自チップ実装（要検討）

`AddMovementView.swift:58-80` の種目選択が、横スクロール + 手組みボタン + 独自 Background。

Issue §6 は「独自実装より SwiftUI 標準 Control を優先」としている。選択肢が7つあるため `Picker` の `.segmented` は窮屈だが、`.menu` や `.navigationLink` スタイルなら標準に寄せられる。

ただし現状の横スクロールチップは**1タップで選択でき、記録を10秒以内に終わらせる**という Phase 1 の完了条件に直結している。標準 Picker に替えると2タップ以上になり UX が後退する。

**判断**: 独自実装を維持する妥当性がある。ただし Background は System Metrics へ寄せ、選択状態の表現を見直す。

### 3-4. Tab Bar の最新挙動（未検討）

Issue §4 の `.tabBarMinimizeBehavior(.onScrollDown)` が未適用。

Home / Insights は `ScrollView`、Library / Activity は `List` で、いずれも縦スクロールする。コンテンツを優先する挙動は適合する。

### 3-5. Scroll Edge（要確認）

`OnboardingView.swift:33` の `.background(.bar)` は `safeAreaInset` に付与されている。Issue §10 は「Content を隠すためだけの固定 Background を安易に追加しない」としている。System の Scroll Edge Effect と競合しないか実機確認が必要。

### 3-6. ハードコード値

| 箇所 | 値 | 評価 |
|---|---|---|
| `AddMovementView.swift:95` | `.frame(maxWidth: 80)` | 時間入力欄。Dynamic Type 最大時に窮屈になる可能性 |
| `ActivityView.swift:84` | `.frame(width: Spacing.xl)` | アイコン幅の揃え。トークン経由なので許容 |
| `CornerRadius.card/button/chip` | 16 / 12 / 8 | Issue §15 は Concentricity を考慮せよとする。`ConcentricRectangle` の検討対象 |

### 3-7. Toolbar

配置は `.cancellationAction` / `.confirmationAction` / `.primaryAction` / `.topBarLeading` と semantic placement を使用済み。Issue §5 の要求を概ね満たす。

`LibraryView` のみ左に目標設定、右に追加と2つ持つ。目的が異なるので同一グループにまとめない現状は正しい。

### 3-8. アクセシビリティ

Issue §18 が求める確認項目のうち、**Reduce Transparency / Increase Contrast / Bold Text は未確認**。Glass を導入すると透明度が絡むため、導入と同時に確認が要る。

---

## 4. 変更計画

Architecture 制約（Domain / UseCase / Repository / Data / Persistence は変更しない）を守る。すべて Presentation 層に閉じる。

### Phase 2 — Foundation

1. `CornerRadius` を見直す。System の Concentricity に委ねられる箇所はトークンを使わない
2. `Typography` は semantic style のみなので維持

### Phase 3 — System Components

3. Tab Bar に `.tabBarMinimizeBehavior(.onScrollDown)` を適用
4. Quick Add / Onboarding の主要ボタンを `.glassProminent` へ
5. `OnboardingView` の `.background(.bar)` の要否を実機で確認

### Phase 4 — Core Screens

6. `HomeView` / `InsightsView` を `List` + `Section` ベースへ寄せ、System Metrics に追従させる
7. 手組みカードの独自 Background を削減

### Phase 5 — Secondary

8. `AddMovementView` のチップの Background を System へ寄せる
9. `.frame(maxWidth: 80)` を Dynamic Type 対応へ

### Phase 6-7 — States / QA

10. Light / Dark / Reduce Transparency / Increase Contrast / Reduce Motion / Dynamic Type / ja・en で全画面確認

---

## 5. 変更リスク

| 変更 | リスク | 対応 |
|---|---|---|
| Home / Insights の List 化 | UI テストの要素構造が変わる | `accessibilityIdentifier` を維持し、テストを先に確認 |
| Tab Bar minimize | スクロール中にタブが隠れ、UI テストのタップが失敗する | テスト側でスクロール位置を制御 |
| Glass ボタン | 背景によって可読性が落ちる | Reduce Transparency / Increase Contrast で確認 |
| チップの Background 変更 | 選択状態が分かりにくくなる | 記号併記（`.isSelected` トレイト）は維持 |

---

## 6. 結論

**「Liquid Glass 風の独自デザインを作る」作業は不要だった。** 現状に独自 Glass 模倣は無く、やるべきは System の既定値に道を譲ることだった。

---

## 7. 実施した変更

### System の既定値へ道を譲る

| 変更 | 対象 |
|---|---|
| 手組みカード → `List` + `Section` | `HomeView` / `InsightsView` |
| 独自 Background の全廃 | 上記2画面 + `AddMovementView` + `OnboardingView` |
| `CornerRadius` トークンの削除 | 全画面。System の Concentricity に委ねる |
| `Typography` の semantic style への置換 | `.headline` / `.body` / `.caption` 等を直接使う |
| 選択チップの独自 Background → `.bordered` + `.capsule` | `AddMovementView` |
| 時間入力の `.frame(maxWidth: 80)` 削除 | `AddMovementView` |

`Typography` は `metric` のみ残した。進捗の数値を読み違えないための rounded design であり、System の semantic style では代替できないアプリ固有の要求のため。

### Functional Layer への標準 Glass

| 変更 | 対象 |
|---|---|
| `.borderedProminent` → `.glassProminent` | Home の Quick Add、Onboarding の開始ボタン |
| `safeAreaInset` へ移動 | Home の Quick Add。Content ではなく操作要素のため |
| `.background(.bar)` の削除 | Onboarding。Glass の下に不透明な帯を敷くと透過が死ぬ |

Content Layer には Glass を一切使っていない。

### Tab Bar

`.tabBarMinimizeBehavior(.onScrollDown)` を適用。全タブが縦スクロールするため、コンテンツを優先する挙動が適合する。

---

## 8. QA 結果

`QACapture` で Light / Dark / Reduce Transparency / Increase Contrast を撮影して確認した（確認後に削除）。

- **Light / Dark** — 成立。System Color のみ使用のため自動追従
- **Reduce Transparency** — 成立。System が Glass を不透明へ自動的に切り替え、可読性が保たれる
- **Increase Contrast** — 成立
- **Dynamic Type 最大** — 成立。文字が折り返され、`List` なので下部も到達可能

達成状態は色（tint）とチェックマーク記号の両方で示しており、色だけに依存していない。

テスト: ユニット180件 + UI 5件、すべて pass。
