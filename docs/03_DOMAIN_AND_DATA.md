# 03. Domain & Data Design

## 1. Core Domain Model

```text
User Preferences
      |
      v
     Goal
      |
      v
Goal Progress <----- Book / MovementSession
      |
      v
   Home Summary
```

---

# 2. Book

```swift
struct Book: Identifiable, Equatable, Sendable {
    let id: UUID

    var title: String
    var author: String?
    var isbn: String?
    var coverURL: URL?

    var status: ReadingStatus

    var startedAt: Date?
    var finishedAt: Date?

    var rating: Int?
    var note: String?

    var createdAt: Date
    var updatedAt: Date
}
```

---

# 3. ReadingStatus

```swift
enum ReadingStatus: String, Codable, CaseIterable, Sendable {
    case wantToRead
    case reading
    case finished
    case paused
}
```

---

# 4. MovementSession

```swift
struct MovementSession: Identifiable, Equatable, Sendable {
    let id: UUID

    var type: MovementType
    var performedAt: Date
    var durationMinutes: Int?
    var note: String?

    var createdAt: Date
    var updatedAt: Date
}
```

---

# 5. MovementType

```swift
enum MovementType: String, Codable, CaseIterable, Sendable {
    case strength
    case running
    case walking
    case sports
    case cycling
    case swimming
    case other
}
```

「Exercise」ではなく「Movement」とする。

理由:

- 筋トレだけに限定しない
- ゴルフ、散歩、スポーツも含めやすい
- アプリの思想と一致

---

# 6. Goal

MVPでは汎用化しすぎない。

```swift
enum GoalKind: String, Codable, Sendable {
    case finishedBooks
    case movementSessions
}
```

```swift
enum GoalPeriod: String, Codable, Sendable {
    case week
    case month
}
```

```swift
struct Goal: Identifiable, Equatable, Sendable {
    let id: UUID
    var kind: GoalKind
    var target: Int
    var period: GoalPeriod
}
```

Default:

```text
Reading:
1 book / month

Movement:
2 sessions / week
```

オンボーディングで変更可能。

---

# 7. GoalProgress

```swift
struct GoalProgress: Equatable, Sendable {
    let goal: Goal
    let current: Int
    let target: Int
    let period: DateInterval

    var ratio: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1)
    }

    var isAchieved: Bool {
        current >= target
    }

    var remaining: Int {
        max(target - current, 0)
    }
}
```

---

# 8. Period Semantics

日付ロジックは必ず`Calendar`ベース。

Week:

ユーザーのlocaleに従いつつ、
内部仕様として`Calendar.autoupdatingCurrent`を利用。

注意:

- ISO weekとlocale weekを混ぜない
- timezone changeを考慮
- `Date`の単純な秒差で週を計算しない

---

# 9. Reading Goal Calculation

MVP:

```text
finishedAt ∈ currentMonth
```

で読了冊数をカウント。

ReadingStatusだけではなく`finishedAt`をsource of truthにする。

---

# 10. Movement Goal Calculation

MVP:

```text
performedAt ∈ currentWeek
```

のMovementSession件数。

同じ日に複数Movementを記録した場合:

MVPでは **session数として複数カウント可能**。

ただしUX上のgamingが問題になれば、
「1日最大1 session count」へ変更可能。

初期は余計な制限を入れない。

---

# 11. Paceria History

```swift
struct PeriodAchievement: Equatable, Sendable {
    let period: DateInterval
    let current: Int
    let target: Int

    var isAchieved: Bool {
        current >= target
    }
}
```

Recent 8-week movement:

```text
✓ ✓ × ✓ ✓ ✓ × ✓

6 / 8 weeks on pace
```

Reading:

```text
last 6 months
✓ × ✓ ✓ ✓ ✓

5 / 6 months on pace
```

---

# 12. Why Not Daily Streak

Daily streakは以下を暗黙的に要求する。

```text
今日やらなければ継続が壊れる
```

Paceriaでは、

```text
この期間で自分が決めた量を満たせたか
```

だけを見る。

したがって、Domain上も`DailyStreak`を中心概念にしない。

---

# 13. Consistency

Domain name:

```swift
struct ConsistencySummary {
    let achievedPeriods: Int
    let totalPeriods: Int
}
```

UI:

```text
6 of 8 weeks on pace
```

内部ではratioを計算してよいが、
MVP UIで点数化しない。

---

# 14. HomeSummary

```swift
struct HomeSummary: Equatable, Sendable {
    let reading: GoalProgress
    let movement: GoalProgress
    let recentWins: [RecentWin]
}
```

---

# 15. RecentWin

```swift
enum RecentWin: Equatable, Sendable {
    case bookStarted(title: String)
    case bookFinished(title: String)
    case movementLogged(type: MovementType)
    case readingGoalAchieved
    case movementGoalAchieved
}
```

最大3件程度。

「feed」にしすぎない。

---

# 16. Repository Interfaces

## BookRepository

```swift
protocol BookRepository: Sendable {
    func fetchAll() async throws -> [Book]
    func fetch(status: ReadingStatus) async throws -> [Book]
    func fetch(id: UUID) async throws -> Book?
    func save(_ book: Book) async throws
    func delete(id: UUID) async throws

    func finishedCount(in interval: DateInterval) async throws -> Int
}
```

---

## MovementRepository

```swift
protocol MovementRepository: Sendable {
    func fetch(in interval: DateInterval) async throws -> [MovementSession]
    func save(_ session: MovementSession) async throws
    func delete(id: UUID) async throws

    func count(in interval: DateInterval) async throws -> Int
}
```

---

## GoalRepository

```swift
protocol GoalRepository: Sendable {
    func readingGoal() async throws -> Goal
    func movementGoal() async throws -> Goal

    func saveReadingGoal(_ goal: Goal) async throws
    func saveMovementGoal(_ goal: Goal) async throws
}
```

---

# 17. UseCases

## CalculateGoalProgressUseCase

Input:

```text
Goal
Date
```

Output:

```text
GoalProgress
```

Repositoryから対象期間のcountを取得。

---

## FinishBookUseCase

責務:

- status → finished
- finishedAt設定
- persistence
- goal achievement判定
- analytics event

---

## GetHomeSummaryUseCase

使用:

- GoalRepository
- BookRepository
- MovementRepository

Output:

- Reading progress
- Movement progress
- Recent wins

---

# 18. Persistence Schema

## SwiftData BookRecord

```text
id UUID unique
title String
author String?
isbn String?
coverURLString String?
statusRawValue String
startedAt Date?
finishedAt Date?
rating Int?
note String?
createdAt Date
updatedAt Date
```

## MovementRecord

```text
id UUID unique
typeRawValue String
performedAt Date
durationMinutes Int?
note String?
createdAt Date
updatedAt Date
```

## GoalRecord

```text
id UUID unique
kindRawValue String unique
target Int
periodRawValue String
updatedAt Date
```

---

# 19. Migration

Schema versionを初期から定義。

```text
PaceriaSchemaV1
```

将来:

```text
V2:
- page tracking
- custom movement categories
```

MigrationPlanを追加。

---

# 20. Book Metadata API

Book登録の摩擦を下げるため、
将来的にISBN検索またはタイトル検索を使用。

Interface:

```swift
protocol BookMetadataService: Sendable {
    func search(query: String) async throws -> [BookMetadata]
    func lookup(isbn: String) async throws -> BookMetadata?
}
```

外部API固有DTOをDomainへ漏らさない。

MVP初版は手入力でも成立する。

---

# 21. HealthKit

Phase 2。

用途候補:

- Workout import

ただしHealthKitデータを取り込む場合でも、
PaceriaのMovementSessionへnormalizeする。

```text
HealthKit Workout
       ↓
HealthKitMovementMapper
       ↓
MovementSession
```

DomainはHealthKitを知らない。

---

# 22. iCloud / CloudKit

MVP local-only。

Phase 2:

SwiftData + CloudKitを検討。

サーバー独自実装は、

- social
- account
- cross-platform

が必要になるまで導入しない。
