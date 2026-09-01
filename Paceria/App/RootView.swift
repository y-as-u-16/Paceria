import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router

    let container: AppContainer

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab(value: AppTab.home) {
                HomeView(
                    viewModel: container.makeHomeViewModel(),
                    makeAddMovementViewModel: container.makeAddMovementViewModel,
                    makeAddBookViewModel: container.makeAddBookViewModel
                )
            } label: {
                Label("tab.home", systemImage: "house")
                    .accessibilityIdentifier("tab.home")
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
                    .accessibilityIdentifier("tab.library")
            }

            Tab(value: AppTab.activity) {
                ActivityView(
                    viewModel: container.makeActivityViewModel(),
                    makeAddViewModel: container.makeAddMovementViewModel
                )
            } label: {
                Label("tab.activity", systemImage: "figure.walk")
                    .accessibilityIdentifier("tab.activity")
            }

            Tab(value: AppTab.insights) {
                PlaceholderScreen(titleKey: "tab.insights")
            } label: {
                Label("tab.insights", systemImage: "chart.bar")
                    .accessibilityIdentifier("tab.insights")
            }
        }
    }
}

/// Phase 2 以降で各 Feature の View へ差し替える。
private struct PlaceholderScreen: View {
    let titleKey: LocalizedStringKey

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label(titleKey, systemImage: "hourglass")
            } description: {
                Text("placeholder.description")
            }
            .navigationTitle(titleKey)
        }
    }
}
