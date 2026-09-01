# Paceria

読書と運動を「自分のペース」で記録する iOS アプリ。SwiftUI + SwiftData。

設計ドキュメントは [docs/](docs/) を参照。

- [01_PRODUCT_REQUIREMENTS.md](docs/01_PRODUCT_REQUIREMENTS.md) — 何を作るか
- [02_ARCHITECTURE.md](docs/02_ARCHITECTURE.md) — レイヤー構成と依存方向
- [03_DOMAIN_AND_DATA.md](docs/03_DOMAIN_AND_DATA.md) — Entity と永続化
- [04_MVP_AND_ROADMAP.md](docs/04_MVP_AND_ROADMAP.md) — Phase 0〜6 の実装順

## 開発フロー

**修正も新規開発も、必ず Issue → ブランチ → 実装の順で進める。main で直接作業しない。**

1. `gh issue list --state all` で該当 Issue の有無を確認する（Phase ごとの Issue は作成済み）
2. 無ければ Issue を作成する。書式は既存 Issue に合わせる（`## 目的` / `## やること` のチェックリスト / `## 参考`）
3. Issue 番号を含むブランチを切る
   - `feat/<番号>-<slug>` — 新規機能
   - `fix/<番号>-<slug>` — バグ修正
   - `chore/<番号>-<slug>` — 設定・雑務
4. 実装してコミットする。コミットメッセージは1行の日本語

## ラベル体系

| 接頭辞 | 意味 |
|---|---|
| `layer:` | domain / data / presentation / app |
| `feature:` | reading / movement / goals / home / insights |
| `phase:` | 0〜6、mvp |
| `infra:` | ci / cd |

## パブリックリポジトリ注意事項

- `DEVELOPMENT_TEAM` は `""` に保つ。Xcode で開くたび自動で書き戻されるため、混入したら `git checkout -- Paceria.xcodeproj/project.pbxproj`
- 新規 Swift ファイルの `// Created by ...` ヘッダーコメントは削除する
- commit author はリポジトリローカル設定を使う（実メールを公開しない）
