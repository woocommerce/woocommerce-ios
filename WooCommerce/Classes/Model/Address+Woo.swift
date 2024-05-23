import Foundation
import Contacts

#if canImport(Yosemite)
import Yosemite
#elseif canImport(NetworkingWatchOS)
import NetworkingWatchOS
#endif


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


    /// Returns the Postal Address, formatted and ready for display.
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

    /// Indicates if an address has only empty values.
    ///
    var isEmpty: Bool {
        self == .empty
    }

#if !os(watchOS)
    /// Erases the address components that are also part of a Tax Rate. Call this if you want to unlink an address from a tax rate.
    ///
    func resettingTaxRateComponents() -> Address {
        copy(city: "",
             state: "",
             postcode: "",
             country: "")
    }

    /// Changes the location components (city, state, postcode, country) to those of the passed tax rate. The other components remain unmodified.
    ///
    func applyingTaxRate(taxRate: TaxRate) -> Address {
        resettingTaxRateComponents().copy(city: taxRate.cities.first ?? taxRate.city,
                                          state: taxRate.state,
                                          postcode: taxRate.postcodes.first ?? taxRate.postcode,
                                          country: taxRate.country)

    }

    /// Generates an Address object from a TaxRate object data
    ///
    static func from(taxRate: TaxRate) -> Address {
        // We take the first city and postcode to keep it simple, even if they don't match
        // If cities and postcodes are empty we try to use the deprecated properties `city`, `postcode` in case they have an older Woo version
        Address.empty.copy(city: taxRate.cities.first ?? taxRate.city,
                           state: taxRate.state,
                           postcode: taxRate.postcodes.first ?? taxRate.postcode,
                           country: taxRate.country)
    }
#endif
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

        return address1 + "\n" + address2
    }


    /// Returns a CNPostalAddress with the receiver's properties
    ///
    var postalAddress: CNPostalAddress {
        let refinedAddress = refineAddressState()
        let address = CNMutablePostalAddress()

        address.street = refinedAddress.combinedAddress
        address.city = refinedAddress.city
        address.state = refinedAddress.state
        address.postalCode = refinedAddress.postcode
        address.country = refinedAddress.country
        address.isoCountryCode = refinedAddress.country

        return address
    }


    func refineAddressState() -> Address {
#if !os(watchOS)
        // https://github.com/woocommerce/woocommerce-ios/issues/5851
        // The backend gives us the state code in the state field.
        // For these countries we should show the state name instead, as the code is not identifiable (e.g. JP01 -> Hokkaido)
        guard ["JP", "TR"].contains(country),
              let stateName = LocallyStoredStateNameRetriever().retrieveLocallyStoredStateName(of: self) else {
            return self
        }

        return copy(state: stateName)
#else
        // Watch app does not have a local storage of countries.
        // In this case we don't apply any special treatment
        return self
#endif
    }
}
