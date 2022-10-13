import Foundation
import Storage

// MARK: - Storage.CustomerSearchResult: ReadOnlyConvertible
extension Storage.CustomerSearchResult: ReadOnlyConvertible {
    /// Updates the `Storage.CustomerSearchResult` from the ReadOnly representation (`Networking.WCAnalyticsCustomer`)
    ///
    public func update(with searchResult: Yosemite.WCAnalyticsCustomer) {
        customerID = searchResult.userID
    }
    
    /// Returns a ReadOnly (`Networking.WCAnalyticsCustomer`) version of the `Storage.CustomerSearchResult`
    public func toReadOnly() -> Yosemite.WCAnalyticsCustomer {
        return WCAnalyticsCustomer(userID: customerID, name: "")
    }
}
