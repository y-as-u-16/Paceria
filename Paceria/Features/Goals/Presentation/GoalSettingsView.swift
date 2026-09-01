import SwiftUI

struct GoalSettingsView: View {
    @State private var viewModel: GoalSettingsViewModel

    init(viewModel: GoalSettingsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("goals.title")
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .loaded(let reading, let movement):
            Form {
                goalSection(
                    titleKey: "goals.reading.title",
                    footerKey: "goals.reading.footer",
                    goal: reading,
                    identifier: "goal.reading",
                    onTarget: { target in Task { await viewModel.updateReading(target: target) } },
                    onPeriod: { period in Task { await viewModel.updateReading(period: period) } }
                )

                goalSection(
                    titleKey: "goals.movement.title",
                    footerKey: "goals.movement.footer",
                    goal: movement,
                    identifier: "goal.movement",
                    onTarget: { target in Task { await viewModel.updateMovement(target: target) } },
                    onPeriod: { period in Task { await viewModel.updateMovement(period: period) } }
                )
            }
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

    private func goalSection(
        titleKey: LocalizedStringKey,
        footerKey: LocalizedStringKey,
        goal: Goal,
        identifier: String,
        onTarget: @escaping (Int) -> Void,
        onPeriod: @escaping (GoalPeriod) -> Void
    ) -> some View {
        Section {
            Stepper(value: targetBinding(goal, onTarget), in: GoalSettingsViewModel.minimumTarget...GoalSettingsViewModel.maximumTarget) {
                LabeledContent("goals.field.target") {
                    Text(goal.unitKey(count: goal.target))
                }
            }
            .accessibilityIdentifier("\(identifier).target")

            Picker("goals.field.period", selection: periodBinding(goal, onPeriod)) {
                ForEach(GoalPeriod.allCases, id: \.self) { period in
                    Text(period.labelKey).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("\(identifier).period")
        } header: {
            Text(titleKey)
        } footer: {
            Text(footerKey)
        }
    }

    private func targetBinding(_ goal: Goal, _ onChange: @escaping (Int) -> Void) -> Binding<Int> {
        Binding(get: { goal.target }, set: onChange)
    }

    private func periodBinding(_ goal: Goal, _ onChange: @escaping (GoalPeriod) -> Void) -> Binding<GoalPeriod> {
        Binding(get: { goal.period }, set: onChange)
    }
}
