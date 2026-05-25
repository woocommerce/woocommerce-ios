import Foundation
import Contacts
import NetworkingCore

extension Address {
    /// Returns the First + LastName combined according to language rules and Locale.
    ///
    var fullName: String {
        var components = PersonNameComponents()
        components.givenName = firstName
        components.familyName = lastName

        return PersonNameComponentsFormatter.localizedString(from: components, style: .medium, options: [])
    }

    /// Returns the Postal Address, formatted and ready for display.
    ///
    var formattedPostalAddress: String? {
        return postalAddress.formatted(as: .mailingAddress)
    }
}

// MARK: - Private Methods
//
private extension Address {
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

    /// Returns the two Address Lines combined (if there are, effectively, two lines).
    /// Per US Post Office standardized rules for address lines. Ref. https://pe.usps.com/text/pub28/28c2_001.htm
    ///
    var combinedAddress: String {
        guard let address2, address2.isEmpty == false else {
            return address1
        }

        return address1 + "\n" + address2
    }
}
