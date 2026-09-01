import Foundation
import SwiftData
import Testing
@testable import Paceria

@Suite("SwiftDataGoalRepository")
struct SwiftDataGoalRepositoryTests {

    private func makeRepository() throws -> SwiftDataGoalRepository {
        SwiftDataGoalRepository(modelContainer: try ModelContainerFactory.makeInMemory())
    }

    @Test("未設定なら読書の既定値を返す")
    func returnsReadingDefault() async throws {
        #expect(try await makeRepository().readingGoal() == Goal.defaultReading)
    }

    @Test("未設定なら運動の既定値を返す")
    func returnsMovementDefault() async throws {
        #expect(try await makeRepository().movementGoal() == Goal.defaultMovement)
    }

    @Test("保存した読書目標を読み出せる")
    func persistsReadingGoal() async throws {
        let repository = try makeRepository()
        let goal = Goal(kind: .finishedBooks, target: 3, period: .month)

        try await repository.saveReadingGoal(goal)
        let loaded = try await repository.readingGoal()

        #expect(loaded.target == 3)
        #expect(loaded.period == .month)
    }

    @Test("保存した運動目標を読み出せる")
    func persistsMovementGoal() async throws {
        let repository = try makeRepository()

        try await repository.saveMovementGoal(Goal(kind: .movementSessions, target: 5, period: .week))

        #expect(try await repository.movementGoal().target == 5)
    }

    @Test("読書と運動の目標は互いに影響しない")
    func goalsAreIndependent() async throws {
        let repository = try makeRepository()

        try await repository.saveReadingGoal(Goal(kind: .finishedBooks, target: 9, period: .week))

        #expect(try await repository.movementGoal() == Goal.defaultMovement)
    }

    @Test("上書き保存しても重複しない")
    func overwritesInsteadOfDuplicating() async throws {
        let repository = try makeRepository()

        try await repository.saveReadingGoal(Goal(kind: .finishedBooks, target: 2, period: .month))
        try await repository.saveReadingGoal(Goal(kind: .finishedBooks, target: 4, period: .week))

        let loaded = try await repository.readingGoal()
        #expect(loaded.target == 4)
        #expect(loaded.period == .week)
    }

    @Test("読むだけでは永続化しない")
    func readingDoesNotPersist() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let repository = SwiftDataGoalRepository(modelContainer: container)

        _ = try await repository.readingGoal()

        let context = ModelContext(container)
        #expect(try context.fetch(FetchDescriptor<GoalRecord>()).isEmpty)
    }

    @Test("未知の period は既定値へ倒す")
    func unknownPeriodFallsBack() async throws {
        let container = try ModelContainerFactory.makeInMemory()
        let repository = SwiftDataGoalRepository(modelContainer: container)
        let context = ModelContext(container)
        context.insert(
            GoalRecord(
                id: UUID(),
                kindRawValue: GoalKind.finishedBooks.rawValue,
                target: 3,
                periodRawValue: "quarter",
                updatedAt: .now
            )
        )
        try context.save()

        let loaded = try await repository.readingGoal()

        #expect(loaded.period == Goal.defaultReading.period)
        #expect(loaded.target == 3)
    }
}

@Suite("GoalSettingsViewModel")
@MainActor
struct GoalSettingsViewModelTests {

    private func makeViewModel() throws -> (GoalSettingsViewModel, SwiftDataGoalRepository) {
        let repository = SwiftDataGoalRepository(modelContainer: try ModelContainerFactory.makeInMemory())
        return (GoalSettingsViewModel(repository: repository), repository)
    }

    @Test("初期状態は loading")
    func initialStateIsLoading() throws {
        #expect(try makeViewModel().0.state == .loading)
    }

    @Test("読み込むと既定値が入る")
    func loadsDefaults() async throws {
        let (viewModel, _) = try makeViewModel()

        await viewModel.load()

        #expect(viewModel.readingGoal == Goal.defaultReading)
        #expect(viewModel.movementGoal == Goal.defaultMovement)
    }

    @Test("目標値を変更すると永続化される")
    func updatesTarget() async throws {
        let (viewModel, repository) = try makeViewModel()
        await viewModel.load()

        await viewModel.updateReading(target: 5)

        #expect(viewModel.readingGoal?.target == 5)
        #expect(try await repository.readingGoal().target == 5)
    }

    @Test("期間を変更すると永続化される")
    func updatesPeriod() async throws {
        let (viewModel, repository) = try makeViewModel()
        await viewModel.load()

        await viewModel.updateMovement(period: .month)

        #expect(try await repository.movementGoal().period == .month)
    }

    @Test("0 以下の目標は最小値へ丸める", arguments: [0, -3])
    func clampsBelowMinimum(target: Int) async throws {
        let (viewModel, _) = try makeViewModel()
        await viewModel.load()

        await viewModel.updateReading(target: target)

        #expect(viewModel.readingGoal?.target == GoalSettingsViewModel.minimumTarget)
    }

    @Test("大きすぎる目標は上限へ丸める")
    func clampsAboveMaximum() async throws {
        let (viewModel, _) = try makeViewModel()
        await viewModel.load()

        await viewModel.updateReading(target: 1000)

        #expect(viewModel.readingGoal?.target == GoalSettingsViewModel.maximumTarget)
    }

    @Test("片方の変更がもう片方に波及しない")
    func updatesAreIndependent() async throws {
        let (viewModel, _) = try makeViewModel()
        await viewModel.load()

        await viewModel.updateReading(target: 7)

        #expect(viewModel.movementGoal == Goal.defaultMovement)
    }
}
