import SwiftUI

struct BookDetailView: View {
    @State private var viewModel: BookDetailViewModel
    @State private var note: String = ""
    @State private var isConfirmingDelete = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: BookDetailViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
            .onChange(of: viewModel.state) { _, state in
                if case .deleted = state { dismiss() }
                if case .loaded(let book) = state, note.isEmpty { note = book.note ?? "" }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .loaded(let book):
            detail(book)
        case .deleted:
            ProgressView()
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

    private func detail(_ book: Book) -> some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(book.title)
                        .font(Typography.sectionTitle)

                    if let author = book.author {
                        Text(author)
                            .font(Typography.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }

            Section("reading.field.status") {
                Picker("reading.field.status", selection: statusBinding(book)) {
                    ForEach(ReadingStatus.displayOrder, id: \.self) { status in
                        Text(status.labelKey).tag(status)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
                .accessibilityIdentifier("book.status")
            }

            Section("reading.field.rating") {
                RatingPicker(rating: book.rating) { rating in
                    Task { await viewModel.updateRating(rating) }
                }
            }

            Section("reading.field.note") {
                TextField("reading.field.note.placeholder", text: $note, axis: .vertical)
                    .lineLimit(3...8)
                    .onSubmit { Task { await viewModel.updateNote(note) } }
                    .accessibilityIdentifier("book.note")
            }

            Section {
                Button("reading.delete", role: .destructive) { isConfirmingDelete = true }
                    .accessibilityIdentifier("book.delete.detail")
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("common.done") {
                    Task { await viewModel.updateNote(note) }
                }
            }
        }
        .confirmationDialog("reading.delete.confirm", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("common.delete", role: .destructive) {
                Task { await viewModel.delete() }
            }
            Button("common.cancel", role: .cancel) {}
        }
    }

    private func statusBinding(_ book: Book) -> Binding<ReadingStatus> {
        Binding(
            get: { book.status },
            set: { status in Task { await viewModel.changeStatus(to: status) } }
        )
    }
}

private struct RatingPicker: View {
    let rating: Int?
    let onChange: (Int?) -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    // 同じ星を押したら解除。評価は任意項目のため取り消せる必要がある。
                    onChange(rating == value ? nil : value)
                } label: {
                    Image(systemName: (rating ?? 0) >= value ? "star.fill" : "star")
                        .foregroundStyle(.tint)
                        .frame(minWidth: Layout.minimumTouchTarget, minHeight: Layout.minimumTouchTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("reading.rating.star \(value)")
                .accessibilityAddTraits((rating ?? 0) >= value ? [.isSelected] : [])
            }
        }
    }
}
