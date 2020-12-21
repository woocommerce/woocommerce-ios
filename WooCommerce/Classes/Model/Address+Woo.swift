import Foundation
import Contacts
import Yosemite


// Yosemite.Address Helper Methods
//
extension Address {

    /// Returns the First + LastName combined according to language rules and Locale.
    ///
    var fullName: String {
        var components = PersonNameComponents()
        components.givenName = firstName
        components.familyName = lastName

        return PersonNameComponentsFormatter.localizedString(from: components, style: .medium, options: [])
    }

    /// Returns the `fullName` and `company` (on a new line). If either the `fullname` or `company` is empty,
    /// then a single line is returned containing the other value.
    ///
    var fullNameWithCompany: String {
        var output: [String] = []

        if fullName.isEmpty == false {
            output.append(fullName)
        }
        if let company = company, company.isEmpty == false {
            output.append(company)
        }

        return output.joined(separator: "\n")
    }

    /// Returns the Postal Address, formated and ready for display.
    ///
    var formattedPostalAddress: String? {
        return postalAddress.formatted(as: .mailingAddress)
    }

    /// Returns the `fullName`, `company`, and `address`. Basically this var combines the
    /// `fullNameWithCompany` & `formattedPostalAddress` vars.
    ///
    var fullNameWithCompanyAndAddress: String {
        var output: [String] = [fullNameWithCompany]

        if let formattedPostalAddress = formattedPostalAddress, formattedPostalAddress.isEmpty == false {
            output.append(formattedPostalAddress)
        }

        return output.joined(separator: "\n")
    }

    /// Returns the (clean) Phone number: contains only decimal digits.
    ///
    var cleanedPhoneNumber: String? {
        return phone?.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    /// Returns the (Clean) Phone Number, as an iOS Actionable URL.
    ///
    var cleanedPhoneNumberAsActionableURL: URL? {
        guard let phone = cleanedPhoneNumber else {
            return nil
        }

        return URL(string: "telprompt://" + phone)
    }

    /// Indicates if there is a Phone Number set (and it's not empty).
    ///
    var hasPhoneNumber: Bool {
        return phone?.isEmpty == false
    }

    /// Indicates if there is an Email Address set (and it's not empty).
    ///
    var hasEmailAddress: Bool {
        return email?.isEmpty == false
    }
}


// MARK: - Private Methods
//
private extension Address {

    /// Returns the two Address Lines combined (if there are, effectively, two lines).
    /// Per US Post Office standardized rules for address lines. Ref. https://pe.usps.com/text/pub28/28c2_001.htm
    ///
    var combinedAddress: String {
        guard let address2 = address2, address2.isEmpty == false else {
            return address1
        }

        return address1 + " " + address2
    }

    /// Returns a CNPostalAddress with the receiver's properties
    ///
    var postalAddress: CNPostalAddress {
        let address = CNMutablePostalAddress()
        address.street = combinedAddress
        address.city = city
        address.state = state
        address.postalCode = postcode
        address.country = country

        return address
    }
}
