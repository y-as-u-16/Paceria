# 01. Product Requirements Document

## 1. Product Overview

### Product Name

Working title:

**Pace**

日本語:

**Pace - 読書と運動の記録**

英語:

**Pace — Read & Move**

「Pace」は、このアプリの中心思想である「他人ではなく、自分のペースで継続する」を直接表現できる。

---

## 2. Vision

### Vision

> 忙しい社会人が、知性と身体の成長を無理なく生活に残し続けられる状態をつくる。

### Mission

ユーザーに毎日の完璧さを要求するのではなく、

- 今週2回運動できた
- 今月1冊読み終えた
- 先月より少しだけ積み上がった

という、小さな成功体験を可視化する。

---

## 3. Problem

既存サービスは、大きく3種類に分かれる。

### 読書記録

主に以下を扱う。

- 読んだ本
- 読みたい本
- 本棚
- レビュー
- ページ数
- 冊数
- SNS

### 運動・筋トレ記録

主に以下を扱う。

- 種目
- 重量
- 回数
- セット
- トレーニング履歴
- PR
- 身体データ

### 習慣トラッカー

主に以下を扱う。

- やった / やっていない
- 日次チェック
- ストリーク
- リマインダー
- 週/月目標

しかし、社会人が「仕事以外にもちゃんと成長したい」という文脈では、

**何を何kg挙げたか**
でも
**何日連続で実行したか**
でもなく、

> 最近、ちゃんと本を読み、身体も動かせているか

を一目で知りたいケースがある。

Paceはここを扱う。

---

## 4. Target User

### Primary Persona

20〜40代の社会人。

以下のような人を想定する。

- 仕事以外にも自己成長したい
- 読書を年間数冊〜数十冊したい
- ジム、ランニング、スポーツ等を継続したい
- 毎日実施することにはこだわらない
- 記録はしたいが入力作業は増やしたくない
- 高機能な筋トレアプリほど細かい管理は不要
- SNSで他人と競争するより、自分の積み上げを見たい

---

## 5. Jobs To Be Done

### Functional Job

> 読書と運動の記録を、1つのアプリで簡単に残したい。

### Emotional Job

> 「最近何もできていない」という感覚ではなく、自分が積み上げているものを確認したい。

### Social Job

> 忙しくても仕事だけで終わらず、知性と身体の両方を磨いている自分でありたい。

---

# 6. Competitive Landscape

2026年8月時点の公開情報をもとに整理。

## 6.1 Reading

### 読書メーター

特徴:

- 読んだ本 / 読んでいる本 / 積読 / 読みたい本
- 冊数・ページ数のグラフ
- 感想
- コミュニティ
- 本との出会い

Source:
- https://bookmeter.com/help/introduction/about
- https://bookmeter.com/specials/app

### 読書管理ビブリア

特徴:

- シンプルな本登録
- バーコード
- メモ / 感想
- 読書データ
- 本棚

Source:
- https://apps.apple.com/jp/app/id894377244

---

## 6.2 Workout

### Hevy

特徴:

- 筋トレ記録
- Routine
- Sets / Reps / Weight
- Exercise progress
- Calendar
- Workout streak
- Community

特にHevyは「何日連続」ではなく、週ごとのWorkout streakも持つ。

Source:
- https://help.hevyapp.com/hc/en-us/articles/35380117933207
- https://www.hevyapp.com/features/gym-consistency/

---

## 6.3 Habit

### Habitify

特徴:

- Daily / Weekly / Monthly goal
- Weekly habit
- Weekly / Monthly streak
- Skip

したがって、

> 「毎日ではなく週2〜3回でもOK」

だけでは市場上の独自性にならない。

Source:
- https://intercom.help/habitify-app/en/articles/9728009-create-track-a-weekly-habit
- https://intercom.help/habitify-app/en/articles/6113621-learn-about-streak-in-habitify

---

# 7. Positioning

Paceのポジションは、

```text
Book Tracker        Workout Tracker
      \                  /
       \                /
        \              /
         Personal Growth
          Consistency
              |
        Habit Tracker
```

の中央。

ただし「全部入り」にはしない。

---

# 8. Unique Value Proposition

## 8.1 Core Concept

### 「連続日数」ではなく「満たした期間」

一般的なDaily Streak:

```text
月 ✓
火 ✓
水 ×  ← streak reset
木 ✓
```

Pace:

```text
Goal: Workout 2 / week

月 -
火 ✓
水 -
木 -
金 ✓
土 -
日 -

Week Achievement: 100%
Consistency: 6 successful weeks
```

休息日は失敗扱いしない。

---

## 8.2 Dual Balance

ホーム画面で「知」と「体」の2軸を表示。

例:

```text
今週

READ
███████░░░  70%

MOVE
██████████ 100%

Balance
Good
```

重要なのは、両方を100%に強制しないこと。

「今月は仕事が忙しいから読書1冊、運動週2」のようにユーザー自身がペースを決める。

---

## 8.3 Small Wins

大きな目標だけではなく、以下を成功として扱う。

読書:

- 本を読み始めた
- 10ページ読んだ
- 読了した
- メモを1つ残した

運動:

- ジムに行った
- 20分歩いた
- ランニングした
- スポーツした

ただしMVPでは細かすぎる入力を要求しない。

---

## 8.4 Gentle Consistency

Paceでは以下を禁止する。

- 赤色で「失敗」
- streak resetを過度に強調
- 「3日サボっています」
- 連続日数だけを成果として表示

代わりに、

```text
あと1回で今週のペース達成
```

```text
今月も自分のペースを守れました
```

```text
過去8週間のうち6週間達成
```

と表現する。

---

# 9. Product Principles

1. **記録は10秒以内**
2. **休むことを失敗にしない**
3. **数字を増やしすぎない**
4. **他人との比較を入れない**
5. **過去の自分との比較だけを扱う**
6. **読書と運動の専門アプリになりすぎない**
7. **ホームを見れば現在地がわかる**

---

# 10. MVP Features

## 10.1 Home

表示:

- 今週 / 今月のPace
- Reading progress
- Movement progress
- 最近の記録
- Small Winメッセージ

例:

```text
Good evening.

YOUR PACE

Reading
1 / 2 books this month

Movement
2 / 2 sessions this week

This week is on pace.
```

---

## 10.2 Reading

### Book states

- Want to Read
- Reading
- Finished
- Paused

### Book data

- title
- author
- cover
- ISBN
- startedAt
- finishedAt
- optional memo
- optional rating

### Input

MVP:

- title search
- manual entry

可能なら:

- ISBN / barcode scan

---

## 10.3 Movement

筋トレ専用にしない。

`MovementType`

- Strength
- Running
- Walking
- Sports
- Cycling
- Swimming
- Other

記録項目:

- type
- date
- duration optional
- memo optional

StrengthのSets / Reps / WeightはMVP対象外。

理由:

そこまで実装するとHevy等の専用アプリと真正面から競合し、
Paceの「シンプルな継続記録」から外れる。

---

# 11. Flexible Goals

Goal例:

```text
Reading
2 books / month

Movement
2 sessions / week
```

将来的には:

```text
Reading
120 pages / week

Movement
150 minutes / week
```

も可能。

MVPでは以下に限定。

- Reading: books / month
- Movement: sessions / week

設定を限定することでUXを簡潔に保つ。

---

# 12. Consistency Score

単純なDaily streakを使わない。

### Pace Rate

直近N期間における達成期間の割合。

```text
Pace Rate =
achievedPeriods / completedPeriods
```

例:

```text
直近8週間
6週間でWorkout goal達成

Pace Rate = 75%
```

UIでは「75点」と採点するより、

```text
6 of last 8 weeks on pace
```

のように事実として表示する。

---

# 13. Balance

読書と運動の達成を2軸で見る。

```text
Reading Achievement = 100%
Movement Achievement = 100%

→ Balanced
```

```text
Reading = 100%
Movement = 50%

→ Reading is on pace.
   One movement session left this week.
```

「Balance Score 62点」のようなブラックボックス指標はMVPでは作らない。

---

# 14. Information Architecture

Tab Bar:

```text
Home
Library
+
Activity
Insights
```

SettingsはHome右上。

中央 `+`:

```text
Add

Read
Movement
```

---

# 15. Screens

## Home

- greeting
- current pace cards
- Quick Add
- recent wins

## Library

- Reading
- Want to Read
- Finished
- Paused

## Book Detail

- cover
- title
- author
- status
- dates
- memo
- rating

## Activity

- activity history
- filter
- weekly progress

## Add Movement

- type
- date
- optional duration
- optional note

## Insights

- monthly reading
- weekly movement
- successful periods
- 8-week / 6-month trend

## Goal Settings

- reading goal
- movement goal

---

# 16. Notification Policy

通知は補助。

MVPでは初期OFFでもよい。

将来的に:

```text
Sunday afternoon:
あと1回で今週のMovement Pace達成です
```

は禁止ではないが、

```text
筋トレを3日サボっています
```

のような罪悪感を煽る表現は使わない。

---

# 17. Social / Sharing Policy

Paceは**アプリ内SNSを実装しない**。

これはMVP上の一時的な対象外ではなく、プロダクト方針とする。

実装しないもの:

- フォロー / フォロワー
- タイムライン
- いいね
- コメント
- ランキング
- 公開プロフィール
- ユーザー同士の比較

理由:

- 「他人ではなく自分のペース」という思想と競合する
- SNS運用・モデレーション・通報対応等の負荷を増やさない
- プロダクトを読書SNS / Fitness SNSへ変質させない

一方、**外部共有は許可する**。

共有方法:

- iOS標準Share Sheet
- 成果カード画像
- テキスト共有

共有先はアプリ側で限定しない。

ユーザーはX、Instagram、LINE、メッセージ等へ自由に共有できる。

成果カードは「他人との比較」ではなく、
**自分の積み上げを外部へ共有するための出口**として扱う。

---

# 18. Out of Scope for MVP

- アプリ内SNS
- フォロー
- いいね / コメント
- タイムライン
- ランキング
- AIチャット
- 詳細筋トレメニュー
- Set / Reps / Weight
- カロリー管理
- 体重管理
- 読書SNS
- 本のレコメンド
- Gamification currency
- Character育成
- チーム
- Web版

---

# 19. Success Metrics

MVPではユーザー数より、プロダクト仮説を測る。

### Activation

初回起動から24時間以内に

- goal設定
- BookまたはMovementを1件記録

### Week 1

- 2カテゴリのどちらかを2回以上記録

### Retention

- W1
- W4
- W8

### Core Behavior

- `period_goal_achieved`

が複数期間発生しているユーザー率。

---

# 20. MVP Product Hypothesis

> ユーザーは「毎日継続」というプレッシャーより、「自分で決めた週/月ペースを守れている」という可視化の方が、読書・運動を長期的に続けやすい。

この仮説をMVPで検証する。
