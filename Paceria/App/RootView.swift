import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab(value: AppTab.home) {
                PlaceholderScreen(titleKey: "tab.home")
            } label: {
                Label("tab.home", systemImage: "house")
            }

            Tab(value: AppTab.library) {
                PlaceholderScreen(titleKey: "tab.library")
            } label: {
                Label("tab.library", systemImage: "books.vertical")
            }

            Tab(value: AppTab.activity) {
                PlaceholderScreen(titleKey: "tab.activity")
            } label: {
                Label("tab.activity", systemImage: "figure.walk")
            }

            Tab(value: AppTab.insights) {
                PlaceholderScreen(titleKey: "tab.insights")
            } label: {
                Label("tab.insights", systemImage: "chart.bar")
            }
        }
    }
}

/// Phase 1 以降で各 Feature の View へ差し替える。
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

#Preview {
    RootView()
        .environment(AppRouter())
}
