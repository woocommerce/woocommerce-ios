import Foundation
import Storage

// MARK: - Storage.WCAnalyticsCustomer: ReadOnlyConvertible
//
extension Storage.WCAnalyticsCustomer: ReadOnlyConvertible {

    /// Updates the `Storage.WCAnalyticsCustomer` with a ReadOnly representation `Networking.WCAnalyticsCustomer`
    ///
    public func update(with customer: Yosemite.WCAnalyticsCustomer) {
        customerID = customer.userID
        username = customer.name
        email = "" // TODO: not yet implemented in Networking
        customerName = "" // TODO: not yet implemented in Networking
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> WCAnalyticsCustomer {
        return WCAnalyticsCustomer(userID: customerID, name: username ?? "")
    }
}
