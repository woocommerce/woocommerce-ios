import Foundation
import Storage

// MARK: - Storage.WCAnalyticsCustomer: ReadOnlyConvertible
//
extension Storage.WCAnalyticsCustomer: ReadOnlyConvertible {

    /// Updates the `Storage.WCAnalyticsCustomer` using the ReadOnly representation (`Networking.WCAnalyticsCustomer`)
    ///
    /// - Parameter customer: ReadOnly representation of WCAnalyticsCustomer
    ///
    public func update(with customer: Yosemite.WCAnalyticsCustomer) {
        siteID = customer.siteID
        customerID = customer.customerID
        userID = customer.userID
        name = customer.name
        email = customer.email
        username = customer.username
        dateRegistered = customer.dateRegistered
        dateLastActive = customer.dateLastActive
        ordersCount = Int64(customer.ordersCount)
        totalSpend = NSDecimalNumber(decimal: customer.totalSpend)
        averageOrderValue = NSDecimalNumber(decimal: customer.averageOrderValue)
        country = customer.country
        region = customer.region
        city = customer.city
        postcode = customer.postcode
    }

    /// Returns a ReadOnly (`Networking.WCAnalyticsCustomer`) version of the `Storage.WCAnalyticsCustomer`
    ///
    public func toReadOnly() -> Yosemite.WCAnalyticsCustomer {
        return WCAnalyticsCustomer(siteID: siteID,
                                   customerID: customerID,
                                   userID: userID,
                                   name: name,
                                   email: email,
                                   username: username,
                                   dateRegistered: dateRegistered,
                                   dateLastActive: dateLastActive,
                                   ordersCount: Int(ordersCount),
                                   totalSpend: totalSpend?.decimalValue ?? 0,
                                   averageOrderValue: averageOrderValue?.decimalValue ?? 0,
                                   country: country ?? String(),
                                   region: region ?? String(),
                                   city: city ?? String(),
                                   postcode: postcode ?? String())
    }
}
