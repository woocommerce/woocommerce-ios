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

        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<[Order]>.self, from: response).data
        } else {
            return try decoder.decode([Order].self, from: response)
        }
    }
}
