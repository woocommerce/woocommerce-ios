protocol ResponseDataValidator {
    /// Throws an error contained in a given Data Instance (if any).
    ///
    func validate(data: Data) throws -> Void
}

/// Placeholder implementation for `ResponseDataValidator`.
///
final class PlaceholderDataValidator: ResponseDataValidator {
    func validate(data: Data) throws {
        // no-op
    }
}
