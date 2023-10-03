struct CountryListMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of Country Entities.
    ///
    func map(response: Data) throws -> [Country] {
        try extract(from: response)
    }
}
