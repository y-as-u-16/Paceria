# 02. Architecture Design

## 1. Architecture Decision

### Adopt

- Swift
- SwiftUI
- Feature-based structure
- Clean Architecture principles
- MVVM
- Swift Concurrency
- SwiftData
- Observation (`@Observable`) where deployment target permits
- XCTest / Swift Testing

### Architecture Style

**Feature-based Pragmatic Clean Architecture**

完全な3層テンプレートを全Featureへ機械的に複製しない。

---

# 2. Why This Architecture

PaceはMVP時点では小〜中規模。

しかし以下のルールはUIから分離したい。

- 週目標判定
- 月目標判定
- 期間境界
- Pace判定
- 読了処理
- Insights集計

一方、

- 単純なSettings取得
- 一覧の表示
- UI内の一時的なselection

にまでUseCaseを作ると過剰設計になる。

したがって、

```text
View
  ↓
ViewModel
  ↓
UseCase (when business rule exists)
  ↓
Repository Protocol
  ↓
Repository Implementation
  ↓
SwiftData / API
```

を基本としつつ、

```text
ViewModel
  ↓
Repository Protocol
```

も単純CRUDでは許可する。

---

# 3. Dependency Rule

```text
Presentation
    ↓
Domain
    ↑
Data
```

Domainは以下をimportしない。

- SwiftUI
- SwiftData
- UIKit
- URLSession implementation detail

Foundationは必要最小限で使用可能。

---

# 4. Recommended Project Structure

```text
Pace/
├── App/
│   ├── PaceApp.swift
│   ├── AppContainer.swift
│   ├── AppRouter.swift
│   └── RootView.swift
│
├── Features/
│   ├── Home/
│   │   ├── Presentation/
│   │   │   ├── HomeView.swift
│   │   │   ├── HomeViewModel.swift
│   │   │   └── Components/
│   │   └── Domain/
│   │       └── GetHomeSummaryUseCase.swift
│   │
│   ├── Reading/
│   │   ├── Presentation/
│   │   │   ├── LibraryView.swift
│   │   │   ├── LibraryViewModel.swift
│   │   │   ├── BookDetailView.swift
│   │   │   ├── BookDetailViewModel.swift
│   │   │   └── AddBookView.swift
│   │   ├── Domain/
│   │   │   ├── Models/
│   │   │   │   ├── Book.swift
│   │   │   │   └── ReadingStatus.swift
│   │   │   ├── Repositories/
│   │   │   │   └── BookRepository.swift
│   │   │   └── UseCases/
│   │   │       ├── AddBookUseCase.swift
│   │   │       └── FinishBookUseCase.swift
│   │   └── Data/
│   │       ├── SwiftDataBookRepository.swift
│   │       └── BookMapper.swift
│   │
│   ├── Movement/
│   │   ├── Presentation/
│   │   ├── Domain/
│   │   └── Data/
│   │
│   ├── Goals/
│   │   ├── Presentation/
│   │   ├── Domain/
│   │   │   ├── Models/
│   │   │   ├── Repositories/
│   │   │   └── UseCases/
│   │   └── Data/
│   │
│   └── Insights/
│       ├── Presentation/
│       └── Domain/
│
├── Core/
│   ├── Domain/
│   │   ├── DatePeriod.swift
│   │   ├── GoalProgress.swift
│   │   └── AppError.swift
│   ├── Data/
│   │   ├── Persistence/
│   │   │   ├── ModelContainerFactory.swift
│   │   │   └── Models/
│   │   └── Network/
│   ├── DesignSystem/
│   │   ├── Components/
│   │   ├── Typography.swift
│   │   └── Spacing.swift
│   └── Utilities/
│
└── Resources/
    ├── Localizable.xcstrings
    └── Assets.xcassets
```

---

# 5. Feature Boundary Rule

「Feature-based」は、

> 全Featureが必ず Presentation / Domain / Data の3フォルダを持つ

という意味ではない。

必要なものだけ作る。

例:

```text
Home/
├── HomeView.swift
└── HomeViewModel.swift
```

から開始してよい。

Homeのロジックが成長したら:

```text
Home/
├── Presentation/
└── Domain/
```

へ昇格する。

---

# 6. Domain Ownership

Feature同士でEntityを重複定義しない。

### Reading owns

- Book
- ReadingStatus

### Movement owns

- MovementSession
- MovementType

### Goals owns

- Goal
- GoalPeriod
- GoalTarget
- GoalProgress

### Core owns

Feature横断で本当に共有されるものだけ。

- DatePeriod
- AppError
- Clock abstraction if needed

---

# 7. MVVM

## View

責務:

- rendering
- user interaction forwarding
- local presentation-only state

禁止:

- DB query
- goal calculation
- business rules
- networking

---

## ViewModel

責務:

- ViewState作成
- async operation
- navigation intent
- UseCase / Repository呼び出し
- error → display state

例:

```swift
@MainActor
@Observable
final class HomeViewModel {
    private let getHomeSummary: GetHomeSummaryUseCase

    private(set) var state: State = .loading

    init(getHomeSummary: GetHomeSummaryUseCase) {
        self.getHomeSummary = getHomeSummary
    }

    func load() async {
        do {
            state = .loaded(try await getHomeSummary.execute())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
```

---

# 8. UseCase Policy

UseCaseを作る基準:

### Create UseCase

以下のいずれかを満たす。

- 複数Repositoryを使う
- ドメインルールがある
- トランザクション境界になる
- 複数画面から再利用
- テスト対象として独立価値がある

例:

- FinishBookUseCase
- CalculateGoalProgressUseCase
- GetHomeSummaryUseCase

### Do Not Create UseCase

単なる:

```text
repository.fetchBooks()
```

の1行ラッパーしかない場合。

---

# 9. Repository

Repository ProtocolはDomainに置く。

```swift
protocol BookRepository: Sendable {
    func books(status: ReadingStatus?) async throws -> [Book]
    func book(id: Book.ID) async throws -> Book?
    func save(_ book: Book) async throws
    func delete(id: Book.ID) async throws
}
```

Implementation:

```text
Features/Reading/Data/SwiftDataBookRepository.swift
```

---

# 10. Persistence

MVP:

**SwiftData local-first**

理由:

- 1ユーザー
- 個人記録
- オフライン価値が高い
- MVPでbackendを持つ価値が薄い
- Apple platformとの相性

App公開後、

- 複数端末
- iPad
- backup

需要が確認できればCloudKitを検討。

---

# 11. SwiftData Boundary

Domain Entityをそのまま`@Model`にしない。

Persistence Model:

```swift
@Model
final class BookRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var author: String?
    var statusRawValue: String
    var startedAt: Date?
    var finishedAt: Date?
}
```

Domain:

```swift
struct Book: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var author: String?
    var status: ReadingStatus
    var startedAt: Date?
    var finishedAt: Date?
}
```

Mapperで変換。

理由:

- DomainをSwiftDataから独立
- migrationの影響を局所化
- test容易性
- 将来CloudKit/APIへ切替可能

---

# 12. Dependency Injection

外部DI libraryはMVPでは不要。

Composition Root:

```text
AppContainer
```

例:

```swift
@MainActor
final class AppContainer {
    let bookRepository: any BookRepository
    let movementRepository: any MovementRepository
    let goalRepository: any GoalRepository

    init(modelContainer: ModelContainer) {
        bookRepository = SwiftDataBookRepository(container: modelContainer)
        movementRepository = SwiftDataMovementRepository(container: modelContainer)
        goalRepository = SwiftDataGoalRepository(container: modelContainer)
    }
}
```

ViewModel生成もContainer経由。

---

# 13. Navigation

SwiftUI `NavigationStack`.

Route:

```swift
enum AppRoute: Hashable {
    case bookDetail(Book.ID)
    case addBook
    case addMovement
    case goalSettings
}
```

Tab:

```swift
enum AppTab {
    case home
    case library
    case activity
    case insights
}
```

NavigationPathを巨大なGlobal Routerへ集約しすぎない。

RootレベルのみAppRouterを持ち、
Feature内部navigationはFeature側へ残す。

---

# 14. Concurrency

原則:

- UI State: `@MainActor`
- Repository API: `async throws`
- Data model: `Sendable`を意識
- callback APIを新規作成しない
- Combineは必要な箇所以外使わない

---

# 15. Error Handling

Domain error:

```swift
enum AppError: Error, Equatable {
    case notFound
    case validation(ValidationError)
    case persistence
    case network
    case unknown
}
```

UIへはViewModelでPresentation Errorへ変換。

---

# 16. Localization

初期からString Catalog:

```text
Localizable.xcstrings
```

対応:

- Japanese
- English

View内へ日本語文字列を直書きしない。

---

# 17. Design System

MVPから最小構成を持つ。

```text
Core/DesignSystem/
```

対象:

- spacing
- corner radius
- typography
- PaceCard
- EmptyState
- PrimaryButton
- ProgressIndicator

独自Design Systemを巨大化させない。

---

# 18. Analytics Boundary

将来Analytics SDKを入れる場合も、

ViewからSDKを直接呼ばない。

```swift
protocol AnalyticsTracking {
    func track(_ event: AnalyticsEvent)
}
```

Event例:

```text
book_added
book_finished
movement_logged
goal_changed
period_goal_achieved
```

---

# 19. Architecture Rules

以下をLint / Review ruleとして扱う。

### MUST

- ViewからRepository Implementationを直接参照しない
- DomainからSwiftUIをimportしない
- DomainからSwiftDataをimportしない
- Repository Protocolは実装より内側
- UI文言はLocalization
- 日付集計はCalendarを明示

### SHOULD

- ViewModelは@MainActor
- async/await
- immutable domain model preference
- Value Objectで意味を表現

### AVOID

- `Manager`万能クラス
- `Utils.swift`
- Singleton依存
- 巨大AppState
- すべてをUseCase化
- Feature間の直接ViewModel参照
