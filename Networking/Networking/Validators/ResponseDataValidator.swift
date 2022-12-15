protocol ResponseDataValidator {
    /// Throws an error contained in a given Data Instance (if any).
    ///
    func validate(data: Data) throws -> Void
}

struct DummyResponseDataValidator: ResponseDataValidator {
    func validate(data: Data) throws -> Void {
        // no-op
    }
}
