import Foundation


/// Mapper: Order
///
struct OrderMapper: Mapper {

    /// Site Identifier associated to the order that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Order Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into [Order].
    ///
    func map(response: Data) throws -> Order {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(OrderEnvelope.self, from: response).order
    }
}


/// OrdersEnvelope Disposable Entity
///
/// `Load Order` endpoint returns the requested order document in the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct OrderEnvelope: Decodable {
    let order: Order

    private enum CodingKeys: String, CodingKey {
        case order = "data"
    }
}
