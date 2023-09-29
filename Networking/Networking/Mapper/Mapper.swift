/// Defines a Mapping Entity that will be used to parse a Backend Response.
///
protocol Mapper {

    /// Defines the Mapping Return Type.
    ///
    associatedtype Output

    /// Maps a Backend Response into a generic entity of Type `Output`. This method *can throw* errors.
    ///
    func map(response: Data) throws -> Output
}

extension Mapper where Output: Decodable {

    func extract(from response: Data, siteID: Int64, dateFormatter: DateFormatter? = .none) throws -> Output {
        return try extract(
            from: response,
            decodingUserInfo: [.siteID: siteID],
            dateFormatter: dateFormatter
        )
    }

    func extract(from response: Data, decodingUserInfo: [CodingUserInfoKey: Any], dateFormatter: DateFormatter? = .none) throws -> Output {
        let decoder = JSONDecoder()
        decoder.userInfo = decodingUserInfo
        if let dateFormatter {
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
        }

        return try extract(from: response, using: decoder)
    }

    func extract(from response: Data, using decoder: JSONDecoder = JSONDecoder()) throws -> Output {
        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<Output>.self, from: response).data
        } else {
            return try decoder.decode(Output.self, from: response)
        }
    }
}
