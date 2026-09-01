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
            ScrollView {
                VStack(spacing: Spacing.l) {
                    InsightsSection(section: movement, titleKey: "insights.movement.title")
                        .accessibilityIdentifier("insights.movement")
                    InsightsSection(section: reading, titleKey: "insights.reading.title")
                        .accessibilityIdentifier("insights.reading")
                }
                .padding(Spacing.m)
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
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(titleKey)
                .font(Typography.sectionTitle)

            if section.achievements.isEmpty {
                Text("insights.empty")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
            } else {
                marks
                Text(consistencyKey)
                    .font(Typography.body)
            }

            Text("insights.current \(section.currentProgress.current) \(section.currentProgress.target)")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(Color(.secondarySystemBackground))
        )
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
