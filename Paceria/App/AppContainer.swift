import Foundation
import SwiftData

/// Composition Root。Repository と UseCase の生成をここへ集約する（02_ARCHITECTURE.md §12）。
/// Phase 1 以降、Feature の Repository をここへ足していく。
@MainActor
final class AppContainer {
    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
}
