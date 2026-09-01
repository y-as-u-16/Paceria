import SwiftUI

struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    @State private var isAddingBook = false

    private let makeAddViewModel: () -> AddBookViewModel
    private let makeDetailViewModel: (UUID) -> BookDetailViewModel
    private let makeGoalSettingsViewModel: () -> GoalSettingsViewModel

    init(
        viewModel: LibraryViewModel,
        makeAddViewModel: @escaping () -> AddBookViewModel,
        makeDetailViewModel: @escaping (UUID) -> BookDetailViewModel,
        makeGoalSettingsViewModel: @escaping () -> GoalSettingsViewModel
    ) {
        _viewModel = State(wrappedValue: viewModel)
        self.makeAddViewModel = makeAddViewModel
        self.makeDetailViewModel = makeDetailViewModel
        self.makeGoalSettingsViewModel = makeGoalSettingsViewModel
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("tab.library")
                .navigationDestination(for: UUID.self) { bookID in
                    BookDetailView(viewModel: makeDetailViewModel(bookID))
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            GoalSettingsView(viewModel: makeGoalSettingsViewModel())
                        } label: {
                            Label("goals.title", systemImage: "target")
                        }
                        .accessibilityIdentifier("goals.open")
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("reading.add.title", systemImage: "plus") {
                            isAddingBook = true
                        }
                        .accessibilityIdentifier("book.add")
                    }
                }
                .sheet(isPresented: $isAddingBook, onDismiss: { Task { await viewModel.load() } }) {
                    AddBookView(viewModel: makeAddViewModel())
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
                Label("reading.empty.title", systemImage: "books.vertical")
            } description: {
                Text("reading.empty.description")
            }
        case .loaded:
            bookList
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

    private var bookList: some View {
        List {
            ForEach(ReadingStatus.displayOrder, id: \.self) { status in
                let books = viewModel.books(for: status)

                if !books.isEmpty {
                    Section(status.labelKey) {
                        ForEach(books) { book in
                            NavigationLink(value: book.id) {
                                BookRow(book: book)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("common.delete", role: .destructive) {
                                    Task { await viewModel.delete(id: book.id) }
                                }
                                .accessibilityIdentifier("book.delete")
                            }
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("book.list")
    }
}

private struct BookRow: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(book.title)
                .font(Typography.cardTitle)
                .lineLimit(2)

            if let author = book.author {
                Text(author)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }

            if let finishedAt = book.finishedAt {
                Text("reading.finishedAt \(finishedAt.formatted(.dateTime.year().month().day()))")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
