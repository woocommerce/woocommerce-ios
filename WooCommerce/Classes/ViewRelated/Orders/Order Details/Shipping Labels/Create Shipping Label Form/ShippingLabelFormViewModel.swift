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
        let accountSettings = ShippingLabelFormViewModel.getStoredAccountSettings()
        let company = ServiceLocator.stores.sessionManager.defaultSite?.name
        let defaultAccount = ServiceLocator.stores.sessionManager.defaultAccount

        self.originAddress = ShippingLabelFormViewModel.fromAddressToShippingLabelAddress(address: originAddress) ??
            ShippingLabelFormViewModel.getDefaultOriginAddress(accountSettings: accountSettings,
                                                               company: company,
                                                               siteAddress: SiteAddress(),
                                                               account: defaultAccount)
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
private extension ShippingLabelFormViewModel {
    // We generate the default origin address using the information
    // of the logged Account and of the website.
    static func getDefaultOriginAddress(accountSettings: AccountSettings?,
                                        company: String?,
                                        siteAddress: SiteAddress,
                                        account: Account?) -> ShippingLabelAddress? {
        let address = Address(firstName: accountSettings?.firstName ?? "",
                              lastName: accountSettings?.lastName ?? "",
                              company: company ?? "",
                              address1: siteAddress.address,
                              address2: siteAddress.address2,
                              city: siteAddress.city,
                              state: siteAddress.state,
                              postcode: siteAddress.postalCode,
                              country: siteAddress.countryName ?? "",
                              phone: "",
                              email: account?.email)
        return fromAddressToShippingLabelAddress(address: address)
    }

    static func fromAddressToShippingLabelAddress(address: Address?) -> ShippingLabelAddress? {
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

    static func getStoredAccountSettings() -> AccountSettings? {
        let storageManager = ServiceLocator.storageManager

        let resultsController = ResultsController<StorageAccountSettings>(storageManager: storageManager, sortedBy: [])
        try? resultsController.performFetch()
        return resultsController.fetchedObjects.first
    }
}
