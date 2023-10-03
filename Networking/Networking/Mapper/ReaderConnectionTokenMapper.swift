struct ReaderConnectionTokenMapper: Mapper {

    /// (Attempts) to convert a dictionary into a connection token.
    ///
    func map(response: Data) throws -> ReaderConnectionToken {
        return try extract(from: response)
    }
}
