import SwiftUI
import SwiftData

@main
struct PaceriaApp: App {
    private let container: AppContainer
    @State private var router = AppRouter()

    init() {
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
            RootView()
                .environment(router)
        }
        .modelContainer(container.modelContainer)
    }
}
