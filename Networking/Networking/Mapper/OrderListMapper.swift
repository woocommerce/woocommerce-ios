import Foundation


/// Mapper: OrderList
///
struct OrderListMapper: Mapper {

    /// Site Identifier associated to the orders that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Order Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into [Order].
    ///
    func map(response: Data) throws -> [Order] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(OrderListEnvelope.self, from: response).orders
    }
}


/// OrderList Disposable Entity:
/// `Load All Orders` endpoint returns all of its orders within the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct OrderListEnvelope: Decodable {
    let orders: [Order]

    private enum CodingKeys: String, CodingKey {
        case orders = "data"
    }
}
