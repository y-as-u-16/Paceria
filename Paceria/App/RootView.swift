import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    let container: AppContainer

    /// UI テストは各機能の導線を検証する。オンボーディングを毎回通すと
    /// 本題に入る前に落ちるため、起動引数で飛ばせるようにする。
    /// @AppStorage の初期読み取りが UserDefaults への書き込みに先行することが
    /// あるため、起動引数もここで直接見る。
    private var skipsOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("-skipOnboarding")
    }

    var body: some View {
        // fullScreenCover で重ねると、閉じた直後にタブの
        // accessibilityIdentifier が解決されないことがある。表示自体を分ける。
        if hasCompletedOnboarding || skipsOnboarding {
            tabs
        } else {
            OnboardingView(viewModel: container.makeOnboardingViewModel()) {
                hasCompletedOnboarding = true
            }
        }
    }

    private var tabs: some View {
        @Bindable var router = router

        return TabView(selection: $router.selectedTab) {
            Tab(value: AppTab.home) {
                HomeView(
                    viewModel: container.makeHomeViewModel(),
                    makeAddMovementViewModel: container.makeAddMovementViewModel,
                    makeAddBookViewModel: container.makeAddBookViewModel
                )
            } label: {
                Label("tab.home", systemImage: "house")
            }

            Tab(value: AppTab.library) {
                LibraryView(
                    viewModel: container.makeLibraryViewModel(),
                    makeAddViewModel: container.makeAddBookViewModel,
                    makeDetailViewModel: container.makeBookDetailViewModel,
                    makeGoalSettingsViewModel: container.makeGoalSettingsViewModel
                )
            } label: {
                Label("tab.library", systemImage: "books.vertical")
            }

            Tab(value: AppTab.activity) {
                ActivityView(
                    viewModel: container.makeActivityViewModel(),
                    makeAddViewModel: container.makeAddMovementViewModel
                )
            } label: {
                Label("tab.activity", systemImage: "figure.walk")
            }

            Tab(value: AppTab.insights) {
                InsightsView(viewModel: container.makeInsightsViewModel())
            } label: {
                Label("tab.insights", systemImage: "chart.bar")
            }
        }
    }
}
