import Foundation

/// Indicates that a merchant store returned a response that the app cannot safely process.
///
/// This error deliberately carries no response data. Callers can safely route it to merchant-facing
/// recovery without exposing the store response.
public struct UnexpectedStoreResponseError: Error, Equatable, Sendable, LocalizedError, CustomStringConvertible {
    public init() {}

    public var description: String {
        "Unexpected store response"
    }

    public var errorDescription: String? {
        description
    }
}
