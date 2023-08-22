import Foundation
import Storage

public protocol StorageCustomerConvertible {
    var loadingID: Int64 { get }
}

extension Yosemite.Customer: StorageCustomerConvertible {
    public var loadingID: Int64 { customerID }
}

extension Yosemite.WCAnalyticsCustomer: StorageCustomerConvertible {
    public var loadingID: Int64 { userID }
}

// MARK: - Storage.Customer: ReadOnlyConvertible
//
extension Storage.Customer: ReadOnlyConvertible {
    public func update(with storageCustomerConvertible: StorageCustomerConvertible) {
        switch storageCustomerConvertible {
        case let customer as Yosemite.Customer:
            update(with: customer)
        case let customer as Yosemite.WCAnalyticsCustomer:
            update(with: customer)
        default:
            break
        }
    }

    /// Updates the `Storage.Customer` from the ReadOnly representation (`Networking.Customer`)
    ///
    public func update(with customer: Yosemite.Customer) {
        customerID = customer.customerID
        siteID = customer.siteID
        email = customer.email
        firstName = customer.firstName
        lastName = customer.lastName
        username = customer.username

        billingFirstName = customer.billing?.firstName
        billingLastName = customer.billing?.lastName
        billingCompany = customer.billing?.company
        billingAddress1 = customer.billing?.address1
        billingAddress2 = customer.billing?.address2
        billingCity = customer.billing?.city
        billingState = customer.billing?.state
        billingPostcode = customer.billing?.postcode
        billingCountry = customer.billing?.country
        billingPhone = customer.billing?.phone
        billingEmail = customer.billing?.email

        shippingFirstName = customer.shipping?.firstName
        shippingLastName = customer.shipping?.lastName
        shippingCompany = customer.shipping?.company
        shippingAddress1 = customer.shipping?.address1
        shippingAddress2 = customer.shipping?.address2
        shippingCity = customer.shipping?.city
        shippingState = customer.shipping?.state
        shippingPostcode = customer.shipping?.postcode
        shippingCountry = customer.shipping?.country
        shippingPhone = customer.shipping?.phone
        shippingEmail = customer.shipping?.email
    }

    /// Updates the `Storage.Customer` from the ReadOnly representation (`Yosemite.WCAnalyticsCustomer`)
    ///
    public func update(with customer: Yosemite.WCAnalyticsCustomer) {
        customerID = customer.userID
        siteID = customer.siteID
        email = customer.email
        username = customer.username

        if let nameComponents = customer.name?.components(separatedBy: " ") {
            // Handle case when there is a middle name: it goes to first name
            firstName = nameComponents.count > 1 ? nameComponents.dropLast().joined(separator: " ") : nameComponents.first
            lastName = nameComponents.count > 1 ? nameComponents.last : nil
        }

        // Reuse information for addresses
        shippingFirstName = firstName
        shippingLastName = lastName
        shippingEmail = email

        billingFirstName = firstName
        billingLastName = lastName
        billingEmail = email
    }

    /// Returns a ReadOnly (`Networking.Customer`) version of the `Storage.Customer`
    ///
    public func toReadOnly() -> Yosemite.Customer {
        return Customer(
            siteID: siteID,
            customerID: customerID,
            email: email ?? "",
            username: username ?? "",
            firstName: firstName ?? "",
            lastName: lastName ?? "",
            billing: createReadOnlyBillingAddress(),
            shipping: createReadOnlyShippingAddress()
        )
    }

    /// Helpers
    private func createReadOnlyBillingAddress() -> Yosemite.Address? {
        Address(firstName: billingFirstName ?? "",
                       lastName: billingLastName ?? "",
                       company: billingCompany ?? "",
                       address1: billingAddress1 ?? "",
                       address2: billingAddress2 ?? "",
                       city: billingCity ?? "",
                       state: billingState ?? "",
                       postcode: billingPostcode ?? "",
                       country: billingCountry ?? "",
                       phone: billingPhone,
                       email: billingEmail
        )
    }

    private func createReadOnlyShippingAddress() -> Yosemite.Address? {
        Address(firstName: shippingFirstName ?? "",
                       lastName: shippingLastName ?? "",
                       company: shippingCompany ?? "",
                       address1: shippingAddress1 ?? "",
                       address2: shippingAddress2 ?? "",
                       city: shippingCity ?? "",
                       state: shippingState ?? "",
                       postcode: shippingPostcode ?? "",
                       country: shippingCountry ?? "",
                       phone: shippingPhone,
                       email: shippingEmail
        )
    }
}
