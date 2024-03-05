import Foundation

/// Used to filter orders by customer
///
public struct CustomerFilter: Codable, Hashable {
    public let id: Int64
    public let firstName: String?
    public let lastName: String?
    public let email: String?
    public let username: String?

    public init(customer: Customer) {
        self.id = customer.customerID
        self.firstName = customer.firstName
        self.lastName = customer.lastName
        self.email = customer.email
        self.username = customer.username
    }
}
