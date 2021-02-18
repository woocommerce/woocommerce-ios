import UIKit
import Yosemite

/// Provides view data for Create Shipping Label, and handles init/UI/navigation actions needed.
///
final class ShippingLabelFormViewModel {

    typealias Section = ShippingLabelFormViewController.Section
    typealias Row = ShippingLabelFormViewController.Row

    let originAddress: ShippingLabelAddress?
    let destinationAddress: ShippingLabelAddress?

    init(originAddress: Address?, destinationAddress: Address?) {
        self.originAddress = ShippingLabelFormViewModel.fromAddressToShippingLabelAddress(address: originAddress) ??
            ShippingLabelFormViewModel.getDefaultOriginAddress()
        self.destinationAddress = ShippingLabelFormViewModel.fromAddressToShippingLabelAddress(address: destinationAddress)
    }

    var sections: [Section] {
        let shipFrom = Row(type: .shipFrom, dataState: .pending, displayMode: .editable)
        let shipTo = Row(type: .shipTo, dataState: .pending, displayMode: .disabled)
        let packageDetails = Row(type: .packageDetails, dataState: .pending, displayMode: .disabled)
        let shippingCarrierAndRates = Row(type: .shippingCarrierAndRates, dataState: .pending, displayMode: .disabled)
        let paymentMethod = Row(type: .paymentMethod, dataState: .pending, displayMode: .disabled)
        let rows: [Row] = [shipFrom, shipTo, packageDetails, shippingCarrierAndRates, paymentMethod]
        return [Section(rows: rows)]
    }
}

// MARK: - Utils
extension ShippingLabelFormViewModel {
    // We generate the default origin address using the information
    // of the logged Account and of the website.
    private static func getDefaultOriginAddress() -> ShippingLabelAddress? {
        // TODO: 2973 - for populating the origin address with the correct first and last name of the store owner
        // we need to explicitly ask for first_name,last_name parameters in loadAccountSettings method
        // and add the new properties to AccountSettings entity.
        let address = Address(firstName: ServiceLocator.stores.sessionManager.defaultAccount?.displayName ?? "",
                lastName: "", company: ServiceLocator.stores.sessionManager.defaultSite?.name ?? "",
                address1: SiteAddress().address,
                address2: SiteAddress().address2,
                city: SiteAddress().city,
                state: SiteAddress().state,
                postcode: SiteAddress().postalCode,
                country: SiteAddress().countryName ?? "",
                phone: "",
                email: ServiceLocator.stores.sessionManager.defaultAccount?.email)
        return fromAddressToShippingLabelAddress(address: address)
    }

    private static func fromAddressToShippingLabelAddress(address: Address?) -> ShippingLabelAddress? {
        guard let address = address else { return nil }

        // In this way we support localized name correctly,
        // because the order is often reversed in a few Asian languages.
        var components = PersonNameComponents()
        components.givenName = address.firstName
        components.familyName = address.lastName

        let shippingLabelAddress = ShippingLabelAddress(company: address.company ?? "",
                                                        name: PersonNameComponentsFormatter.localizedString(from: components, style: .medium, options: []),
                                                        phone: address.phone ?? "",
                                                        country: address.country,
                                                        state: address.state,
                                                        address1: address.address1,
                                                        address2: address.address2 ?? "",
                                                        city: address.city,
                                                        postcode: address.postcode)
        return shippingLabelAddress
    }
}
