/// An `Error` implementation that contains any type of `Error`.
public struct AnyError: Error {
    /// The underlying error.
    public let error: Error

    public init(_ error: Error) {
        if let anyError = error as? AnyError {
            self = anyError
        } else {
            self.error = error
        }
    }
}

extension AnyError: Equatable {
    public static func == (lhs: AnyError, rhs: AnyError) -> Bool {
        return (lhs as NSError) == (rhs as NSError)
    }
}

extension Error {
    /// Converts a generic `Error` to `AnyError` that supports `Equatable`.
    public var toAnyError: AnyError {
        .init(self)
    }
}

extension AnyError: LocalizedError {
    public var errorDescription: String? {
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    public var failureReason: String? {
        return (error as? LocalizedError)?.failureReason
    }

    public var helpAnchor: String? {
        return (error as? LocalizedError)?.helpAnchor
    }

    public var recoverySuggestion: String? {
        return (error as? LocalizedError)?.recoverySuggestion
    }
}
