import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var isAddingMovement = false
    @State private var isAddingBook = false

    private let makeAddMovementViewModel: () -> AddMovementViewModel
    private let makeAddBookViewModel: () -> AddBookViewModel

    init(
        viewModel: HomeViewModel,
        makeAddMovementViewModel: @escaping () -> AddMovementViewModel,
        makeAddBookViewModel: @escaping () -> AddBookViewModel
    ) {
        _viewModel = State(wrappedValue: viewModel)
        self.makeAddMovementViewModel = makeAddMovementViewModel
        self.makeAddBookViewModel = makeAddBookViewModel
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("tab.home")
                .sheet(isPresented: $isAddingMovement, onDismiss: reload) {
                    AddMovementView(viewModel: makeAddMovementViewModel())
                }
                .sheet(isPresented: $isAddingBook, onDismiss: reload) {
                    AddBookView(viewModel: makeAddBookViewModel())
                }
                .task { await viewModel.load() }
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .loaded(let summary):
            summaryList(summary)
        case .failed:
            ContentUnavailableView {
                Label("common.error.title", systemImage: "exclamationmark.triangle")
            } description: {
                Text("common.error.description")
            } actions: {
                Button("common.retry", action: reload)
            }
        }
    }

    /// 行高・余白・角丸は System に委ねる。手組みカードだと OS 更新で
    /// メトリクスが変わったときに取り残される（Issue #14 §12）。
    private func summaryList(_ summary: HomeSummary) -> some View {
        List {
            Section {
                PaceRow(progress: summary.reading, titleKey: "home.reading.title")
                    .accessibilityIdentifier("home.card.reading")
                PaceRow(progress: summary.movement, titleKey: "home.movement.title")
                    .accessibilityIdentifier("home.card.movement")
            }

            if !summary.recentWins.isEmpty {
                Section("home.recentWins.title") {
                    ForEach(Array(summary.recentWins.enumerated()), id: \.offset) { _, win in
                        Label(win.messageKey, systemImage: win.symbolName)
                    }
                }
            }
        }
        .accessibilityIdentifier("home.summary")
        // Quick Add は Content ではなく操作要素。コンテンツの上に浮かせる。
        .safeAreaInset(edge: .bottom) {
            quickAdd
        }
    }

    private var quickAdd: some View {
        HStack(spacing: Spacing.m) {
            QuickAddButton(titleKey: "home.quickAdd.movement", systemImage: "figure.walk") {
                isAddingMovement = true
            }
            .accessibilityIdentifier("home.quickAdd.movement")

            QuickAddButton(titleKey: "home.quickAdd.book", systemImage: "book") {
                isAddingBook = true
            }
            .accessibilityIdentifier("home.quickAdd.book")
        }
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.m)
    }
}

private struct PaceRow: View {
    let progress: GoalProgress
    let titleKey: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text(titleKey)
                    .font(.headline)
                Spacer()
                // 達成を色だけで示さない（04 §11）。記号を併記する。
                if progress.isAchieved {
                    Label("home.achieved.badge", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.tint)
                }
            }

            Text("home.progress.count \(progress.current) \(progress.target)")
                .font(Typography.metric)

            ProgressView(value: progress.ratio)

            Text(HomeCopy.headline(for: progress))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

private struct QuickAddButton: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(titleKey, systemImage: systemImage)
                .frame(maxWidth: .infinity, minHeight: Layout.minimumTouchTarget)
        }
        .buttonStyle(.glassProminent)
    }
}
