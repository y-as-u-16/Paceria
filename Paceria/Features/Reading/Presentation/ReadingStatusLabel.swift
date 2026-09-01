import SwiftUI

extension ReadingStatus {
    /// String Catalog は静的リテラルしか抽出しない。動的生成にするとキーがそのまま表示される。
    var labelKey: LocalizedStringKey {
        switch self {
        case .wantToRead: "reading.status.wantToRead"
        case .reading: "reading.status.reading"
        case .finished: "reading.status.finished"
        case .paused: "reading.status.paused"
        }
    }

    var symbolName: String {
        switch self {
        case .wantToRead: "bookmark"
        case .reading: "book"
        case .finished: "checkmark.circle"
        case .paused: "pause.circle"
        }
    }

    /// 一覧での表示順。読書中を最初に置く。
    static var displayOrder: [ReadingStatus] {
        [.reading, .wantToRead, .finished, .paused]
    }
}

extension BookFormError {
    var messageKey: LocalizedStringKey {
        switch self {
        case .invalid(.emptyTitle): "reading.error.emptyTitle"
        case .invalid: "reading.error.invalid"
        case .saveFailed: "reading.error.saveFailed"
        }
    }
}
