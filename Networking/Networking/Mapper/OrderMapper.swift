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
    func map(response: Data) async throws -> Order {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(OrderEnvelope.self, from: response).order
        } else {
            return try decoder.decode(Order.self, from: response)
        }
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
