@testable import Networking

// MARK: - Allows `DotcomError` comparison ignoring associated values
// Swift forum discussion: https://forums.swift.org/t/operator-for-enums-with-ignored-associated-values/23481/2
//
extension DotcomError {
    enum Case { case empty, unauthorized, invalidToken, requestFailed, noRestRoute, unknown }

    /// `DotcomError` case that ignores associated values.
    /// Should match cases in `DotcomError`.
    var `case`: Case {
        switch self {
        case .empty: return .empty
        case .unauthorized: return .unauthorized
        case .invalidToken: return .invalidToken
        case .requestFailed: return .requestFailed
        case .noRestRoute: return .noRestRoute
        case .unknown: return .unknown
        }
    }
}
