struct DataBoolMapper: Mapper {

    /// (Attempts) to extract the boolean flag from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> Bool {
        try extract(from: response, using: JSONDecoder())
    }
}
