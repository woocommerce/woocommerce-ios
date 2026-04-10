import Foundation

struct MockCustomer {
    let firstName: String
    let lastName: String
    let company: String?
    let address1: String
    let address2: String?
    let city: String
    let state: String
    let postCode: String
    let country: String
    let phone: String?
    let email: String?

    init(
        firstName: String,
        lastName: String,
        company: String? = nil,
        address1: String = "",
        address2: String? = nil,
        city: String = "",
        state: String = "",
        postCode: String = "",
        country: String = "",
        phone: String? = nil,
        email: String? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.company = company
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.state = state
        self.postCode = postCode
        self.country = country
        self.phone = phone
        self.email = email
    }

    var billingAddress: Address {
        .init(
            firstName: firstName,
            lastName: lastName,
            company: company,
            address1: address1,
            address2: address2,
            city: city,
            state: state,
            postcode: postCode,
            country: country,
            phone: phone,
            email: email
        )
    }

    var shippingAddress: Address {
        return billingAddress
    }

    var fullName: String {
        return firstName + " " + lastName
    }

    var defaultEmail: String {
        return firstName + "." + lastName + "@example.com"
    }

    var defaultGravatar: String {
        mockResourceUrlHost + fullName.slugified!
    }
}
