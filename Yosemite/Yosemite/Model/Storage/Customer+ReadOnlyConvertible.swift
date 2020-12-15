import Foundation
import Storage

// MARK: - Storage.Customer: ReadOnlyConvertible
//
extension Storage.Customer: ReadOnlyConvertible {

    /// Updates the Storage.Customer with the ReadOnly.
    ///
    public func update(with customer: Yosemite.Customer) {
        siteID = customer.siteID
        userID = customer.userID
        dateCreated = customer.dateCreated
        dateModified = customer.dateModified
        email = customer.email
        username = customer.username
        firstName = customer.firstName
        lastName = customer.lastName
        avatarUrl = customer.avatarUrl
        role = customer.role.rawValue
        isPaying = customer.isPaying

        if let billingAddress = customer.billingAddress {
            billingFirstName = billingAddress.firstName
            billingLastName = billingAddress.lastName
            billingCompany = billingAddress.company
            billingAddress1 = billingAddress.address1
            billingAddress2 = billingAddress.address2
            billingCity = billingAddress.city
            billingState = billingAddress.state
            billingPostcode = billingAddress.postcode
            billingCountry = billingAddress.country
            billingPhone = billingAddress.phone
            billingEmail = billingAddress.email
        }

        if let shippingAddress = customer.shippingAddress {
            shippingFirstName = shippingAddress.firstName
            shippingLastName = shippingAddress.lastName
            shippingCompany = shippingAddress.company
            shippingAddress1 = shippingAddress.address1
            shippingAddress2 = shippingAddress.address2
            shippingCity = shippingAddress.city
            shippingState = shippingAddress.state
            shippingPostcode = shippingAddress.postcode
            shippingCountry = shippingAddress.country
            shippingPhone = shippingAddress.phone
            shippingEmail = shippingAddress.email
        }
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Customer {
        return Customer(siteID: siteID,
                        userID: userID,
                        dateCreated: dateCreated,
                        dateModified: dateModified,
                        email: email,
                        username: username,
                        firstName: firstName,
                        lastName: lastName,
                        avatarUrl: avatarUrl,
                        role: .init(rawValue: role),
                        isPaying: isPaying,
                        billingAddress: createReadOnlyBillingAddress(),
                        shippingAddress: createReadOnlyShippingAddress())
    }
}

// MARK: - Private Helpers
//
private extension Storage.Customer {

    private func createReadOnlyBillingAddress() -> Yosemite.Address? {
        guard let billingCountry = billingCountry else {
            return nil
        }

        return Address(firstName: billingFirstName ?? "",
                       lastName: billingLastName ?? "",
                       company: billingCompany,
                       address1: billingAddress1 ?? "",
                       address2: billingAddress2,
                       city: billingCity ?? "",
                       state: billingState ?? "",
                       postcode: billingPostcode ?? "",
                       country: billingCountry,
                       phone: billingPhone,
                       email: billingEmail)
    }

    private func createReadOnlyShippingAddress() -> Yosemite.Address? {
        guard let shippingCountry = shippingCountry else {
            return nil
        }

        return Address(firstName: shippingFirstName ?? "",
                       lastName: shippingLastName ?? "",
                       company: shippingCompany,
                       address1: shippingAddress1 ?? "",
                       address2: shippingAddress2,
                       city: shippingCity ?? "",
                       state: shippingState ?? "",
                       postcode: shippingPostcode ?? "",
                       country: shippingCountry,
                       phone: shippingPhone,
                       email: shippingEmail)
    }
}
