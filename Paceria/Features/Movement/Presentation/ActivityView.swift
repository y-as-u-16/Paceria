import SwiftUI

struct ActivityView: View {
    @State private var viewModel: ActivityViewModel
    @State private var isAddingMovement = false

    private let makeAddViewModel: () -> AddMovementViewModel

    init(
        viewModel: ActivityViewModel,
        makeAddViewModel: @escaping () -> AddMovementViewModel
    ) {
        _viewModel = State(wrappedValue: viewModel)
        self.makeAddViewModel = makeAddViewModel
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("tab.activity")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("movement.add.title", systemImage: "plus") {
                            isAddingMovement = true
                        }
                        .accessibilityIdentifier("movement.add")
                    }
                }
                .sheet(isPresented: $isAddingMovement, onDismiss: { Task { await viewModel.load() } }) {
                    AddMovementView(viewModel: makeAddViewModel())
                }
                .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView {
                Label("movement.empty.title", systemImage: "figure.walk")
            } description: {
                Text("movement.empty.description")
            }
        case .loaded(let sessions):
            sessionList(sessions)
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

    private func sessionList(_ sessions: [MovementSession]) -> some View {
        List {
            ForEach(sessions) { session in
                MovementRow(session: session)
                    .swipeActions(edge: .trailing) {
                        Button("common.delete", role: .destructive) {
                            Task { await viewModel.delete(id: session.id) }
                        }
                        .accessibilityIdentifier("movement.delete")
                    }
            }
        }
        .accessibilityIdentifier("movement.list")
    }
}

private struct MovementRow: View {
    let session: MovementSession

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: session.type.symbolName)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: Spacing.xl)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(session.type.labelKey)
                    .font(.headline)

                Text(session.performedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let note = session.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let minutes = session.durationMinutes {
                Text("movement.duration.minutes \(minutes)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
