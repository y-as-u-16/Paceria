import SwiftUI

struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    private let onFinish: () -> Void

    init(viewModel: OnboardingViewModel, onFinish: @escaping () -> Void) {
        _viewModel = State(wrappedValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    concept
                    goalSection
                }
                .padding(Spacing.l)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task {
                        if await viewModel.finish() { onFinish() }
                    }
                } label: {
                    Text("onboarding.start")
                        .frame(maxWidth: .infinity, minHeight: Layout.minimumTouchTarget)
                }
                .buttonStyle(.glassProminent)
                .disabled(viewModel.isSaving)
                .padding(Spacing.l)
                .accessibilityIdentifier("onboarding.start")
            }
            .navigationTitle("onboarding.title")
        }
    }

    private var concept: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("onboarding.concept.headline")
                .font(.title3)

            ForEach(["onboarding.concept.point1", "onboarding.concept.point2", "onboarding.concept.point3"], id: \.self) { key in
                Label(LocalizedStringKey(key), systemImage: "checkmark.circle")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("onboarding.goals.headline")
                .font(.title3)

            Stepper(value: $viewModel.readingTarget, in: GoalSettingsViewModel.minimumTarget...GoalSettingsViewModel.maximumTarget) {
                LabeledContent("onboarding.goals.reading") {
                    Text("goals.unit.books \(viewModel.readingTarget)")
                }
            }
            .accessibilityIdentifier("onboarding.reading")

            Stepper(value: $viewModel.movementTarget, in: GoalSettingsViewModel.minimumTarget...GoalSettingsViewModel.maximumTarget) {
                LabeledContent("onboarding.goals.movement") {
                    Text("goals.unit.sessions \(viewModel.movementTarget)")
                }
            }
            .accessibilityIdentifier("onboarding.movement")

            Text("onboarding.goals.footer")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
