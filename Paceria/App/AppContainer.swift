import Foundation
import SwiftData

/// Composition Root。Repository と ViewModel の生成をここへ集約する（02_ARCHITECTURE.md §12）。
@MainActor
final class AppContainer {
    let modelContainer: ModelContainer
    let movementRepository: any MovementRepository
    let bookRepository: any BookRepository

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.movementRepository = SwiftDataMovementRepository(modelContainer: modelContainer)
        self.bookRepository = SwiftDataBookRepository(modelContainer: modelContainer)
    }

    func makeActivityViewModel() -> ActivityViewModel {
        ActivityViewModel(repository: movementRepository)
    }

    func makeAddMovementViewModel() -> AddMovementViewModel {
        AddMovementViewModel(repository: movementRepository)
    }

    func makeLibraryViewModel() -> LibraryViewModel {
        LibraryViewModel(repository: bookRepository)
    }

    func makeAddBookViewModel() -> AddBookViewModel {
        AddBookViewModel(repository: bookRepository)
    }

    func makeBookDetailViewModel(bookID: UUID) -> BookDetailViewModel {
        BookDetailViewModel(
            bookID: bookID,
            repository: bookRepository,
            finishBook: FinishBookUseCase(repository: bookRepository)
        )
    }
}
