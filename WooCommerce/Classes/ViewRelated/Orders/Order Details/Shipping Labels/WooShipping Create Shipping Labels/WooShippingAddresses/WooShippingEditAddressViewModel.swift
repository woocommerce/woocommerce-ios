import Foundation
import SwiftUI
import Yosemite
import protocol Storage.StorageManagerType

/// View model for editing an address in the Woo Shipping label flow.
final class WooShippingEditAddressViewModel: ObservableObject, Identifiable {
    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType

    enum AddressType {
        case origin
        case destination
    }

    /// Type of address being edited.
    private let addressType: AddressType

    // MARK: Address properties

    let id: String
    @Published var name: String
    @Published var company: String
    @Published var country: String
    @Published var address: String
    @Published var city: String
    @Published var state: String
    @Published var postalCode: String
    @Published var email: String
    @Published var phone: String
    @Published var isDefault: Bool

    /// Whether to show the "save as default" toggle.
    var showSaveAsDefault: Bool {
        addressType == .origin
    }

    /// Whether to show the company field by default.
    @Published var showCompanyField: Bool

    // MARK: Local requirements & validation

    /// Whether the phone number is required.
    private let phoneNumberRequired: Bool

    // TODO: Set status based on initial verified status, whether any changes have been made, and local validation.
    /// Status of the address, based on local validation and remote verification.
    var status: WooShippingAddressStatus

    // MARK: State/Country

    /// ResultsController: Loads Countries from the Storage Layer.
    ///
    private lazy var resultsController: ResultsController<StorageCountry> = {
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController(storageManager: storageManager, matching: nil, sortedBy: [descriptor])
    }()

    /// List of countries that can be used as an origin address.
    var countries: [Country] {
        switch addressType {
        case .origin:
            resultsController.fetchedObjects.filter { Constants.acceptedUSPSCountries.contains($0.code) }
        case .destination:
            resultsController.fetchedObjects
        }
    }

    /// States of the selected country.
    var statesOfSelectedCountry: [StateOfACountry] {
        countries.first { $0.code == country }?.states.sorted { $0.name < $1.name } ?? []
    }

    /// Whether the state is required for the selected country.
    var stateRequired: Bool {
        statesOfSelectedCountry.isNotEmpty
    }

    init(type: AddressType,
         id: String,
         name: String,
         company: String,
         country: String,
         address: String,
         city: String,
         state: String,
         postalCode: String,
         email: String,
         phone: String,
         isDefault: Bool,
         showCompanyField: Bool,
         isVerified: Bool,
         phoneNumberRequired: Bool,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.addressType = type
        self.id = id
        self.name = name
        self.company = company
        self.country = country
        self.address = address
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.email = email
        self.phone = phone
        self.isDefault = isDefault
        self.showCompanyField = showCompanyField
        self.status = isVerified ? .verified : .unverified
        self.phoneNumberRequired = phoneNumberRequired
        self.stores = stores
        self.siteID = stores.sessionManager.defaultStoreID ?? Int64.min
        self.storageManager = storageManager

        fetchCountries()
    }

    convenience init(address: WooShippingOriginAddress,
                     stores: StoresManager = ServiceLocator.stores,
                     storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.init(type: .origin,
                  id: address.id,
                  name: address.fullName,
                  company: address.company,
                  country: address.country,
                  address: address.combinedAddress,
                  city: address.city,
                  state: address.state,
                  postalCode: address.postcode,
                  email: address.email,
                  phone: address.phone,
                  isDefault: address.defaultAddress,
                  showCompanyField: address.company.isNotEmpty,
                  isVerified: address.isVerified,
                  phoneNumberRequired: true,
                  stores: stores,
                  storageManager: storageManager)
    }

    func isRequired(_ field: WooShippingEditAddressView.AddressField) -> Bool {
        switch field {
        case .name:
            return company.isEmpty
        case .company:
            return name.isEmpty
        case .country, .address, .city, .postalCode, .email:
            return true
        case .state:
            return stateRequired
        case .phone:
            return phoneNumberRequired
        }
    }
}

// MARK: Remote
private extension WooShippingEditAddressViewModel {
    func fetchCountries() {
        try? resultsController.performFetch()
        let action = DataAction.synchronizeCountries(siteID: siteID) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success:
                try? self.resultsController.performFetch()
            case .failure:
                break
            }
        }

        stores.dispatch(action)
    }
}

// MARK: Constants
private extension WooShippingEditAddressViewModel {
    enum Constants {
        /// This is hardcoded for now based on: https://git.io/JBuja.
        /// It would be great if this can be fetched remotely.
        ///
        static let acceptedUSPSCountries = [
            "US", // United States
            "PR", // Puerto Rico
            "VI", // Virgin Islands
            "GU", // Guam
            "AS", // American Samoa
            "UM", // United States Minor Outlying Islands
            "MH", // Marshall Islands
            "FM", // Micronesia
            "MP" // Northern Mariana Islands
        ]
    }
}
