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

    private func summaryList(_ summary: HomeSummary) -> some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                PaceCard(progress: summary.reading, titleKey: "home.reading.title")
                    .accessibilityIdentifier("home.card.reading")

                PaceCard(progress: summary.movement, titleKey: "home.movement.title")
                    .accessibilityIdentifier("home.card.movement")

                quickAdd

                if !summary.recentWins.isEmpty {
                    recentWins(summary.recentWins)
                }
            }
            .padding(Spacing.m)
        }
        .accessibilityIdentifier("home.summary")
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
    }

    private func recentWins(_ wins: [RecentWin]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("home.recentWins.title")
                .font(Typography.sectionTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(wins.enumerated()), id: \.offset) { _, win in
                Label(win.messageKey, systemImage: win.symbolName)
                    .font(Typography.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.xs)
            }
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private struct PaceCard: View {
    let progress: GoalProgress
    let titleKey: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text(titleKey)
                    .font(Typography.cardTitle)
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
                .tint(.accentColor)

            Text(HomeCopy.headline(for: progress))
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(Color(.secondarySystemBackground))
        )
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
                .font(Typography.body)
                .frame(maxWidth: .infinity, minHeight: Layout.minimumTouchTarget)
                .padding(.vertical, Spacing.s)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
    }
}
