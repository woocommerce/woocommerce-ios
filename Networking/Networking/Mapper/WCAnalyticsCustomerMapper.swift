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
        let customers = try decoder.decode([WCAnalyticsCustomer].self, from: response)
        return customers
    }

    /// (Attempts) to convert a dictionary into a `WCAnalyticsCustomer` entity
    ///
    func mapUniqueCustomer(response: Data, searchValue: String? = "") throws -> WCAnalyticsCustomer? {
        if searchValue == "" {
            return WCAnalyticsCustomer(userID: 0, name: "")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [.siteID: siteID]
        let customers = try decoder.decode([WCAnalyticsCustomer].self, from: response)
        let customerMatch = customers.filter { $0.name == searchValue }.first
        return customerMatch
    }
}
