import Foundation


/// Mapper: Refund List
///
struct RefundListMapper: Mapper {

    /// Site Identifier associated to the order refund that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Order Refund Endpoints.
    ///
    let siteID: Int64

    /// Order Identifier associated with the refund that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the orderID is not returned in any of the Refund Endpoints.
    ///
    let orderID: Int64


    /// (Attempts) to convert a dictionary into [Refund].
    ///
    func map(response: Data) throws -> [Refund] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]

        return try decoder.decode(RefundsEnvelope.self, from: response).refunds
    }
}


/// RefundsEnvelope Disposable Entity
///
/// `Load Refunds` endpoint returns the requested order refunds document in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct RefundsEnvelope: Decodable {
    let refunds: [Refund]

    private enum CodingKeys: String, CodingKey {
        case refunds = "data"
    }
}
