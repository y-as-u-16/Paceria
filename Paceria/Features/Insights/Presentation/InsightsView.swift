import SwiftUI

struct InsightsView: View {
    @State private var viewModel: InsightsViewModel

    init(viewModel: InsightsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("tab.insights")
                .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .loaded(let reading, let movement):
            List {
                InsightsSection(section: movement, titleKey: "insights.movement.title")
                    .accessibilityIdentifier("insights.movement")
                InsightsSection(section: reading, titleKey: "insights.reading.title")
                    .accessibilityIdentifier("insights.reading")
            }
            .accessibilityIdentifier("insights.summary")
        case .failed:
            ContentUnavailableView {
                Label("common.error.title", systemImage: "exclamationmark.triangle")
            } description: {
                Text("common.error.description")
            } actions: {
                Button("common.retry") { Task { await viewModel.load() } }
            }
        }
    }
}

private struct InsightsSection: View {
    let section: InsightsViewModel.Section
    let titleKey: LocalizedStringKey

    var body: some View {
        Section(titleKey) {
            if section.achievements.isEmpty {
                Text("insights.empty")
                    .foregroundStyle(.secondary)
            } else {
                marks
                Text(consistencyKey)
            }

            Text("insights.current \(section.currentProgress.current) \(section.currentProgress.target)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// 未達を赤で塗らない。達成と未達を同格に並べるのがこのアプリの主張。
    private var marks: some View {
        HStack(spacing: Spacing.s) {
            ForEach(Array(section.achievements.enumerated()), id: \.offset) { _, achievement in
                Image(systemName: achievement.isAchieved ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(achievement.isAchieved ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .accessibilityLabel(achievement.isAchieved ? "insights.mark.achieved" : "insights.mark.notAchieved")
            }
        }
    }

    private var consistencyKey: LocalizedStringKey {
        let summary = section.consistency
        return section.goal.period == .week
            ? "insights.consistency.weeks \(summary.achievedPeriods) \(summary.totalPeriods)"
            : "insights.consistency.months \(summary.achievedPeriods) \(summary.totalPeriods)"
    }
}
