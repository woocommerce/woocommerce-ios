import Contacts

extension Address: Decodable {
    enum AddressStructKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case company = "company"
        case address1 = "address_1"
        case address2 = "address_2"
        case city = "city"
        case state = "state"
        case postcode = "postcode"
        case country = "country"
        case email = "email"
        case phone = "phone"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AddressStructKeys.self)
        let firstName: String = try container.decode(String.self, forKey: .firstName)
        let lastName: String = try container.decode(String.self, forKey: .lastName)
        let company: String? = try container.decodeIfPresent(String.self, forKey: .company)
        let address1: String = try container.decode(String.self, forKey: .address1)
        let address2: String? = try container.decodeIfPresent(String.self, forKey: .address2)
        let city: String = try container.decode(String.self, forKey: .city)
        let state: String = try container.decode(String.self, forKey: .state)
        let postcode: String = try container.decode(String.self, forKey: .postcode)
        let country: String = try container.decode(String.self, forKey: .country)
        let email: String? = try container.decodeIfPresent(String.self, forKey: .email)
        let phone: String? = try container.decodeIfPresent(String.self, forKey: .phone)

        self.init(firstName: firstName, lastName: lastName, company: company, address1: address1, address2: address2, city: city, state: state, postcode: postcode, country: country, email: email, phone: phone)
    }

    func createContact() -> CNContact {
        let contact = CNMutableContact()
        contact.givenName = firstName
        contact.familyName = lastName

        if let organization = company  {
            if organization.isEmpty == false {
                contact.organizationName = organization
            }
        }

        let postalAddress = CNMutablePostalAddress()
        // Per US Post Office standardized rules for address lines
        // https://pe.usps.com/text/pub28/28c2_001.htm
        var combinedAddress: String
        if let addressLine2 = address2 {
            if addressLine2.isEmpty == false {
                combinedAddress = String(format: "%@ %@", [address1, addressLine2])
            } else {
                combinedAddress = address1
            }
        } else {
            combinedAddress = address1
        }
        postalAddress.street = combinedAddress
        postalAddress.city = city
        postalAddress.state = state
        postalAddress.postalCode = postcode

        if let phoneNumber = phone {
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phoneNumber))]
        }

        if let emailAddress = email as NSString? {
            contact.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: emailAddress)]
        }

        contact.postalAddresses = [CNLabeledValue(label: CNLabelWork, value: postalAddress)]

        return contact
    }
}
