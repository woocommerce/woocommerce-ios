/// Mapper: WCPay Reader Location
///
struct RemoteReaderLocationMapper: Mapper {

    /// (Attempts) to convert a dictionary into a location.
    ///
    func map(response: Data) throws -> RemoteReaderLocation {
        let decoder = JSONDecoder()

        return try extract(from: response, using: decoder)
    }
}
