import Foundation

enum AppError: Error, Equatable, Sendable {
    case notFound
    case validation(ValidationError)
    case persistence
    case network
    case unknown
}

enum ValidationError: Error, Equatable, Sendable {
    case emptyTitle
    case targetOutOfRange
    case durationOutOfRange
    case futureDate
}
