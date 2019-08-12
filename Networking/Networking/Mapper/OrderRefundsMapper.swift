import Foundation


/// Mapper: OrderRefund
///
struct OrderRefundsMapper: Mapper {

    /// Site Identifier associated to the order refund that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Order Endpoints.
    ///
    let siteID: Int


    /// (Attempts) to convert a dictionary into [OrderRefund].
    ///
    func map(response: Data) throws -> [OrderRefund] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(OrderRefundsEnvelope.self, from: response).orderRefunds
    }
}


/// OrdersRefundsEnvelope Disposable Entity
///
/// `Load Order` endpoint returns the requested order document in the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct OrderRefundsEnvelope: Decodable {
    let orderRefunds: [OrderRefund]

    private enum CodingKeys: String, CodingKey {
        case orderRefunds = "data"
    }
}
