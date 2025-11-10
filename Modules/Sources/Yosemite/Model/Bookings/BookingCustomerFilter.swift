import Foundation

/// Used to filter bookings by customers
///
public struct BookingCustomerFilter: Codable, Hashable {
    /// ID of the customer
    ///
    public let customerID: Int64

    /// Name of the customer
    ///
    public let name: String

    public init(customerID: Int64, name: String) {
        self.customerID = customerID
        self.name = name
    }
}
