import SwiftUI
import SwiftData

@main
struct PaceriaApp: App {
    private let container: AppContainer
    @State private var router = AppRouter()

    init() {
        // UI テストがオンボーディングの有無を制御できるようにする。
        // @AppStorage は起動時の値を読むため、View 生成前に確定させる。
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-resetOnboarding") {
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        } else if arguments.contains("-skipOnboarding") {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }

        do {
            container = AppContainer(modelContainer: try ModelContainerFactory.make())
        } catch {
            // 永続化ストアを開けないとアプリは何も記録できない。黙って続行すると
            // 記録が消えたように見えるため、原因が分かる形で停止させる。
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .environment(router)
        }
        .modelContainer(container.modelContainer)
    }
}
