import Foundation
import Testing
@testable import Paceria

@Suite("AddMovementViewModel")
@MainActor
struct AddMovementViewModelTests {

    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeViewModel(_ repository: MovementRepositorySpy) -> AddMovementViewModel {
        let now = referenceDate
        return AddMovementViewModel(repository: repository, now: { now })
    }

    @Test("初期値のまま保存できる。記録を10秒以内で終わらせるため")
    func savesWithDefaults() async {
        let repository = MovementRepositorySpy()
        let viewModel = makeViewModel(repository)

        let didSave = await viewModel.save()

        #expect(didSave)
        #expect(await repository.savedSessions.count == 1)
        #expect(viewModel.error == nil)
    }

    @Test("入力した内容が保存される")
    func savesEnteredValues() async {
        let repository = MovementRepositorySpy()
        let viewModel = makeViewModel(repository)
        viewModel.type = .swimming
        viewModel.durationMinutes = 45
        viewModel.note = "プール"

        _ = await viewModel.save()
        let saved = await repository.savedSessions.first

        #expect(saved?.type == .swimming)
        #expect(saved?.durationMinutes == 45)
        #expect(saved?.note == "プール")
    }

    @Test("空白だけのメモは nil として保存する")
    func blankNoteBecomesNil() async {
        let repository = MovementRepositorySpy()
        let viewModel = makeViewModel(repository)
        viewModel.note = "   \n "

        _ = await viewModel.save()

        #expect(await repository.savedSessions.first?.note == nil)
    }

    @Test("メモの前後の空白は取り除く")
    func trimsNote() async {
        let repository = MovementRepositorySpy()
        let viewModel = makeViewModel(repository)
        viewModel.note = "  朝ラン  "

        _ = await viewModel.save()

        #expect(await repository.savedSessions.first?.note == "朝ラン")
    }

    @Test("未来の日時は保存しない")
    func rejectsFutureDate() async {
        let repository = MovementRepositorySpy()
        let viewModel = makeViewModel(repository)
        viewModel.performedAt = referenceDate.addingTimeInterval(3600)

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(viewModel.error == .invalid(.futureDate))
        #expect(await repository.savedSessions.isEmpty)
    }

    @Test("範囲外の時間は保存しない", arguments: [0, -10, 1441])
    func rejectsOutOfRangeDuration(minutes: Int) async {
        let repository = MovementRepositorySpy()
        let viewModel = makeViewModel(repository)
        viewModel.durationMinutes = minutes

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(viewModel.error == .invalid(.durationOutOfRange))
        #expect(await repository.savedSessions.isEmpty)
    }

    @Test("境界値の時間は保存できる", arguments: [1, 1440])
    func acceptsBoundaryDuration(minutes: Int) async {
        let repository = MovementRepositorySpy()
        let viewModel = makeViewModel(repository)
        viewModel.durationMinutes = minutes

        #expect(await viewModel.save())
    }

    @Test("保存に失敗したらエラーを立て、false を返す")
    func reportsSaveFailure() async {
        let viewModel = makeViewModel(MovementRepositorySpy(shouldFail: true))

        let didSave = await viewModel.save()

        #expect(!didSave)
        #expect(viewModel.error == .saveFailed)
    }

    @Test("バリデーション失敗後に修正すれば保存できる")
    func recoversAfterValidationFailure() async {
        let repository = MovementRepositorySpy()
        let viewModel = makeViewModel(repository)
        viewModel.durationMinutes = 9999
        _ = await viewModel.save()

        viewModel.durationMinutes = 30
        let didSave = await viewModel.save()

        #expect(didSave)
        #expect(viewModel.error == nil)
    }
}
