import Foundation
import Observation

enum AppTab: Hashable, CaseIterable {
    case home
    case library
    case activity
    case insights
}

enum AppRoute: Hashable {
    case bookDetail(UUID)
    case goalSettings
}

/// 画面遷移のうち Root レベルのものだけを持つ。Feature 内部の遷移は
/// Feature 側の NavigationStack に残す（02_ARCHITECTURE.md §13）。
@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var presentedSheet: AppSheet?
}

enum AppSheet: Hashable, Identifiable {
    case addBook
    case addMovement

    var id: Self { self }
}
