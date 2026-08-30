# 04. MVP, Delivery & Testing

## 1. MVP Goal

MVPの目的は、

> 「読書 + 運動 + 柔軟な期間目標」という組み合わせが継続体験として価値を持つか

を確認すること。

機能数を増やすことではない。

---

# 2. MVP Scope

## Must

### Onboarding

- App concept
- Reading goal設定
- Movement goal設定

### Home

- Reading progress
- Movement progress
- Quick Add
- Recent Win

### Reading

- add
- list
- status change
- finish
- memo
- delete

### Movement

- add
- history
- delete
- MovementType
- optional duration
- optional note

### Insights

- current period
- recent period achievement

### Settings

- reading goal
- movement goal
- language follows system

---

# 3. Nice to Have

- barcode scan
- book metadata search
- haptics
- widget
- notifications

---

# 4. Explicitly Not MVP

- auth
- backend
- アプリ内SNS
- follow / follower
- timeline
- likes
- comments
- ranking
- detailed workout tracker
- AI
- recommendation
- badges大量実装
- achievement currency
- Apple Watch
- iPad optimization
- Android

---

# 5. Implementation Order

## Phase 0: Foundation

1. Xcode project
2. Git
3. folder skeleton
4. SwiftData container
5. AppContainer
6. navigation
7. Localization
8. basic design tokens

---

## Phase 1: Movement Vertical Slice

最初に最小Featureを縦に通す。

```text
Add Movement
→ Domain
→ Repository
→ SwiftData
→ History
```

これでArchitectureを検証する。

---

## Phase 2: Reading

```text
Book
ReadingStatus
BookRepository
Library
Add Book
Finish Book
```

---

## Phase 3: Goals

```text
Goal
GoalRepository
DatePeriod
CalculateGoalProgress
```

---

## Phase 4: Home

```text
GetHomeSummary
HomeViewModel
Paceria Cards
Recent Wins
```

---

## Phase 5: Insights

- past weeks
- past months
- achievement periods

---

## Phase 6: Polish

- accessibility
- empty states
- haptics
- animations
- App Store assets

---

# 6. Testing Strategy

テストピラミッド:

```text
         UI
       /    \
 Integration
 /          \
Domain Unit Tests
```

Domainを厚め。

---

# 7. Critical Unit Tests

## Date / Period

- week start/end
- month start/end
- timezone
- year boundary
- leap year
- DST where applicable

---

## GoalProgress

```text
0 / 2 -> incomplete
1 / 2 -> incomplete
2 / 2 -> achieved
3 / 2 -> achieved, ratio capped 1
```

---

## Reading

- FinishBook sets finishedAt
- Finished book counted in correct month
- Previous month excluded

---

## Movement

- sessions in current week counted
- previous/next week excluded

---

## Consistency

```text
[true, true, false, true]
→ 3 / 4
```

空配列時の挙動も定義する。

---

# 8. Repository Tests

SwiftData in-memory container。

```text
ModelConfiguration(isStoredInMemoryOnly: true)
```

対象:

- save
- fetch
- delete
- filter
- count

---

# 9. ViewModel Tests

対象:

- loading
- success
- empty
- error
- user action → state transition

Viewのsnapshot testはMVPで必須ではない。

---

# 10. UI Tests

Critical pathだけ。

### Flow A

```text
Launch
→ Set Goal
→ Add Movement
→ Home progress updated
```

### Flow B

```text
Add Book
→ Reading
→ Finish
→ Monthly progress updated
```

---

# 11. Non-functional Requirements

## Performance

- Home launch: local dataなので体感即時
- listは数千件程度でも問題ない構造
- aggregationをView body内で行わない

## Offline

100% core functionality available offline.

## Privacy

MVP local-only。

- account不要
- unnecessary tracking不要
- health data不要

App Store privacy説明を簡潔にできる設計。

## Accessibility

- Dynamic Type
- VoiceOver labels
- 44pt touch target
- 色だけで状態を表現しない
- Reduce Motion考慮

---

# 12. UX Acceptance Criteria

## Logging

Movement:

通常操作で10秒以内。

Book:

手入力でも30秒以内。
metadata search導入後は10秒程度を目標。

---

## Home

初見で以下が3秒以内に分かる。

- 今月の読書状況
- 今週の運動状況
- 次に何をすれば達成か

---

# 13. Copy Guidelines

### Good

```text
あと1回で今週のペース達成
```

```text
今週も自分のペースで進んでいます
```

```text
6 of 8 weeks on pace
```

### Avoid

```text
3日サボっています
```

```text
ストリークが途切れました
```

```text
失敗
```

---

# 14. Design Direction

Visual keywords:

- calm
- restrained
- adult
- quiet confidence
- clean
- minimal

避ける:

- childish gamification
- neon fitness UI
- overly bookish brown UI
- dashboard overload

「自己管理ツール」より、
「静かなPersonal Growth journal」に近づける。

---

# 15. Future Phase 2

優先候補:

- ISBN barcode
- book metadata search
- Widget
- Gentle reminders
- HealthKit import
- CloudKit
- custom movement type
- reading pages optional
- monthly retrospective
- iOS Share Sheet
- achievement share card

---

# 16. Future Phase 3

仮説が確認された場合のみ。

- yearly themes
- personal growth timeline
- optional goal categories
- Apple Watch quick logging
- export
- shareable yearly summary

## Social Feature Policy

以下はPhase 3以降も原則実装しない。

- in-app social graph
- public feed
- likes / comments
- follower ranking

共有は外部SNS・メッセージアプリへ委譲する。

---

# 17. Do Not Expand Into Generic Habit Tracker

重要。

Paceriaへ以下を追加し始めると、

```text
Meditation
Water
Sleep
English
Study
Cleaning
...
```

一般的なHabit Trackerになる。

Paceriaの最初の差別化は、

```text
READ
MOVE
```

という明確な2軸。

カテゴリー追加はユーザー検証後に判断する。

---

# 18. Release Definition of Done

## Product

- Reading goal works
- Movement goal works
- period achievement works
- no daily-streak pressure
- logging is fast

## Engineering

- Domain test coverage for critical rules
- SwiftData repository integration tests
- no Domain → SwiftUI/SwiftData dependency
- localization Japanese/English
- no P0/P1 crash

## UX

- empty state complete
- VoiceOver basic path
- Dynamic Type usable
- dark mode usable

---

# 19. Recommended First Release

Version:

**0.1 Internal**

Goal:

architecture + vertical slice.

Then:

**0.5 TestFlight**

- Reading
- Movement
- Goals
- Home
- Insights

Then:

**1.0 App Store**

Only after actual users can answer:

> 「このアプリを見ると、毎日じゃなくても自分はちゃんと続けていると思える」

with yes.
