import Foundation

enum ReadingStatus: String, Codable, CaseIterable, Sendable {
    case wantToRead
    case reading
    case finished
    case paused
}
