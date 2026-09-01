import Foundation
import Observation

@MainActor
@Observable
final class LibraryViewModel {
    enum State: Equatable {
        case loading
        case empty
        case loaded([ReadingStatus: [Book]])
        case failed
    }

    private(set) var state: State = .loading

    private let repository: any BookRepository

    init(repository: any BookRepository) {
        self.repository = repository
    }

    func load() async {
        state = .loading

        do {
            let books = try await repository.fetchAll()
            state = books.isEmpty ? .empty : .loaded(Dictionary(grouping: books, by: \.status))
        } catch {
            state = .failed
        }
    }

    func books(for status: ReadingStatus) -> [Book] {
        guard case .loaded(let grouped) = state else { return [] }
        return grouped[status] ?? []
    }

    func delete(id: UUID) async {
        do {
            try await repository.delete(id: id)
            await load()
        } catch {
            state = .failed
        }
    }
}
