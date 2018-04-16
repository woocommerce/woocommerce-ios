import Foundation

// MARK: -
//
struct Address {
    let firstName: String
    let lastName: String
    let company: String?
    let address1: String
    let address2: String?
    let city: String
    let state: String
    let postcode: String
    let country: String
    let email: String?
    let phone: String?

    init(firstName: String, lastName: String, company: String?, address1: String, address2: String?, city: String, state: String, postcode: String, country: String, email: String?, phone: String?) {
        self.firstName = firstName
        self.lastName = lastName
        self.company = company
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.state = state
        self.postcode = postcode
        self.country = country
        self.email = email
        self.phone = phone
    }
}
