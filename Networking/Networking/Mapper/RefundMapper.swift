/// Mapper: Refund
///
struct RefundMapper: Mapper {

    /// Site Identifier associated to the refund that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Refund Endpoints.
    ///
    let siteID: Int64

    /// Order Identifier associated with the refund that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the orderID is not returned in any of the Refund Endpoints.
    ///
    let orderID: Int64

    /// (Attempts) to convert a dictionary into a single Refund.
    ///
    func map(response: Data) throws -> Refund {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<Refund>.self, from: response).data
        } else {
            return try decoder.decode(Refund.self, from: response)
        }
    }

    /// (Attempts) to encode a Refund object into JSONEncoded data.
    ///
    func map(refund: Refund) throws -> Data {
        let encoder = JSONEncoder()

        return try encoder.encode(refund)
    }
}
