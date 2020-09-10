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
