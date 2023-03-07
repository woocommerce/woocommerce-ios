protocol ResponseDataValidator {
    /// Throws an error contained in a given Data Instance (if any).
    ///
    func validate(data: Data) throws -> Void
}
