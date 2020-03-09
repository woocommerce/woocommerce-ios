import Foundation


/// Mapper: Order count
///
struct OrderCountMapper: Mapper {

    /// Site Identifier associated to the order that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Order Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into OrderCount.
    ///
    func map(response: Data) throws -> OrderCount {
        let decoder = JSONDecoder()
        let orderCountItems = try decoder.decode(OrderCountEnvelope.self,
                                                 from: response)

        return OrderCount(siteID: siteID,
                          items: orderCountItems.orderCountItems)
    }
}


/// OrderCountEnvelope Disposable Entity:
/// The endpoint to count orders returns all of its data within the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct OrderCountEnvelope: Decodable {
    let orderCountItems: [OrderCountItem]

    private enum CodingKeys: String, CodingKey {
        case orderCountItems = "data"
    }
}
