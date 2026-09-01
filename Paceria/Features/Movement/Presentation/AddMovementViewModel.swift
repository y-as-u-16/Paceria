import Foundation
import Observation

@MainActor
@Observable
final class AddMovementViewModel {
    /// 記録を10秒以内で終わらせるため、初期値のまま保存できる状態から始める
    /// （docs/04_MVP_AND_ROADMAP.md §12）。
    var type: MovementType = .walking
    var performedAt: Date
    var durationMinutes: Int?
    var note: String = ""

    private(set) var isSaving = false
    private(set) var error: AddMovementError?

    private let repository: any MovementRepository
    private let now: @Sendable () -> Date

    init(
        repository: any MovementRepository,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repository = repository
        self.now = now
        self.performedAt = now()
    }

    /// 保存できたら true。View 側の dismiss 判定に使う。
    func save() async -> Bool {
        guard !isSaving else { return false }

        if let failure = validate() {
            error = .invalid(failure)
            return false
        }

        isSaving = true
        defer { isSaving = false }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let session = MovementSession(
            type: type,
            performedAt: performedAt,
            durationMinutes: durationMinutes,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )

        do {
            try await repository.save(session)
            error = nil
            return true
        } catch {
            self.error = .saveFailed
            return false
        }
    }

    private func validate() -> ValidationError? {
        if performedAt > now() { return .futureDate }
        if let minutes = durationMinutes, minutes <= 0 || minutes > 1440 { return .durationOutOfRange }
        return nil
    }
}

enum AddMovementError: Equatable {
    case invalid(ValidationError)
    case saveFailed
}
