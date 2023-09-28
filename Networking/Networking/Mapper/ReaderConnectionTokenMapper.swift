/// Mapper: Card reader connection token
///
struct ReaderConnectionTokenMapper: Mapper {

    /// (Attempts) to convert a dictionary into a connection token.
    ///
    func map(response: Data) throws -> ReaderConnectionToken {
        let decoder = JSONDecoder()

        return try extract(from: response, using: JSONDecoder())
    }
}
