import Foundation

/// Mapper: WCAnalyticsCustomer
///
struct WCAnalyticsCustomerMapper: Mapper {
    /// We're injecting this field by copying it in after parsing responses, because `siteID` is not returned in any of the Customer endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into a `[WCAnalyticsCustomer]` entity
    ///
    func map(response: Data) throws -> [WCAnalyticsCustomer] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [.siteID: siteID]
        do {
            return try decoder.decode(WCAnalyticsCustomerEnvelope.self, from: response).customer
        } catch {
            return try decoder.decode([WCAnalyticsCustomer].self, from: response)
        }
    }
}

private struct WCAnalyticsCustomerEnvelope: Decodable {
    let customer: [WCAnalyticsCustomer]

    private enum CodingKeys: String, CodingKey {
        case customer = "data"
    }
}
