import Foundation


/// Mapper: Order count
///
struct OrderCountMapper: Mapper {
    
    /// Site Identifier associated to the order that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Order Endpoints.
    ///
    let siteID: Int

    /// (Attempts) to convert a dictionary into OrderCount.
    ///
    func map(response: Data) throws -> OrderCount {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]
        
        return try decoder.decode(OrderCount.self, from: response)
    }
}
