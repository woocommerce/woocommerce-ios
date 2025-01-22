import Foundation
import SwiftUI
import Yosemite
import protocol Storage.StorageManagerType
import Combine

/// View model for editing an address in the Woo Shipping label flow.
final class WooShippingEditAddressViewModel: ObservableObject, Identifiable {
    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private var cancellables: Set<AnyCancellable> = []

    enum AddressType {
        case origin
        case destination
    }

    /// Type of address being edited.
    private let addressType: AddressType

    // MARK: Address properties

    let id: String
    @Published var name: WooShippingAddressField
    @Published var company: WooShippingAddressField
    @Published var country: WooShippingAddressField
    @Published var address: WooShippingAddressField
    @Published var city: WooShippingAddressField
    @Published var state: WooShippingAddressField
    @Published var postalCode: WooShippingAddressField
    @Published var email: WooShippingAddressField
    @Published var phone: WooShippingAddressField

    /// Whether the address is the default address for shipping labels; this is only used for origin addresses.
    @Published var isDefaultAddress: Bool

    /// Whether to show the "save as default" toggle, to save the address as the default origin address.
    var showSaveAsDefault: Bool {
        addressType == .origin
    }

    /// Whether to show the company field by default.
    @Published var showCompanyField: Bool

    // MARK: Local requirements & validation

    /// Whether the address has been remotely verified.
    private var isVerified: Bool

    var allFields: [WooShippingAddressField] {
        [name, company, country, address, city, state, postalCode, email, phone]
    }

    /// Fields with validation errors based on local validation.
    var invalidFields: [WooShippingAddressField] {
        allFields.filter { $0.errorMessage != nil }
    }

    /// Whether the phone number is required.
    private let phoneNumberRequired: Bool

    // TODO: Set status to unverified if the address was verified remotely but there are unsaved changes.
    /// Status of the address, based on local validation and remote verification.
    var status: WooShippingAddressStatus {
        switch (isVerified, invalidFields.isEmpty) {
        case (true, true):
            return .verified
        case (false, true):
            return .unverified
        case (_, false):
            return .missingInformation
        }
    }

    // MARK: State/Country

    /// ResultsController: Loads Countries from the Storage Layer.
    ///
    private lazy var resultsController: ResultsController<StorageCountry> = {
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController(storageManager: storageManager, matching: nil, sortedBy: [descriptor])
    }()

    /// Selected country. We observe this to update the `country` property.
    @Published private(set) var selectedCountry: Country?

    /// Selected state. We observe this to update the `state` property.
    @Published private(set) var selectedState: StateOfACountry?

    /// View model for selecting a country from a list.
    var countrySelectorVM: CountrySelectorViewModel {
        let selectedCountryBinding = Binding<AreaSelectorCommandProtocol?>(
            get: { self.selectedCountry },
            set: { self.selectedCountry = $0 as? Country}
        )
        return CountrySelectorViewModel(countries: countries, selected: selectedCountryBinding)
    }

    /// View model for selecting a state from a list.
    var stateSelectorVM: StateSelectorViewModel {
        let selectedStateBinding = Binding<AreaSelectorCommandProtocol?>(
            get: { self.selectedState },
            set: { self.selectedState = $0 as? StateOfACountry }
        )
        return StateSelectorViewModel(states: statesOfSelectedCountry, selected: selectedStateBinding)
    }

    /// List of countries that can be used as an origin address.
    var countries: [Country] {
        switch addressType {
        case .origin:
            resultsController.fetchedObjects.filter { Constants.acceptedUSPSCountries.contains($0.code) }
        case .destination:
            resultsController.fetchedObjects
        }
    }

    /// Whether the address is in the US.
    var isUSAddress: Bool {
        country.value == "US"
    }

    /// States of the selected country.
    var statesOfSelectedCountry: [StateOfACountry] {
        countries.first { $0.code == country.value }?.states.sorted { $0.name < $1.name } ?? []
    }

    /// Whether the state is required for the selected country.
    private var stateRequired: Bool {
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
         isDefaultAddress: Bool,
         showCompanyField: Bool,
         isVerified: Bool,
         phoneNumberRequired: Bool,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.addressType = type
        self.id = id
        self.name = WooShippingAddressField(type: .name, value: name, required: company.isEmpty, validate: { _ in return nil })
        self.company = WooShippingAddressField(type: .company, value: company, required: name.isEmpty, validate: { _ in return nil })
        self.country = WooShippingAddressField(type: .country, value: country, required: true, validate: { newCountry in
            newCountry.isEmpty ? Localization.Validation.country : nil
        })
        self.address = WooShippingAddressField(type: .address, value: address, required: true, validate: { newAddress in
            newAddress.isEmpty ? Localization.Validation.address : nil
        })
        self.city = WooShippingAddressField(type: .city, value: city, required: true, validate: { newCity in
            newCity.isEmpty ? Localization.Validation.city : nil
        })
        self.state = WooShippingAddressField(type: .state, value: state, required: false, validate: { _ in return nil })
        self.postalCode = WooShippingAddressField(type: .postalCode, value: postalCode, required: true, validate: { newPostalCode in
            newPostalCode.isEmpty ? Localization.Validation.postalCode : nil
        })
        self.email = WooShippingAddressField(type: .email, value: email, required: true, validate: { newEmail in
            newEmail.isEmpty ? Localization.Validation.email : nil
        })
        self.phone = WooShippingAddressField(type: .phone, value: phone, required: phoneNumberRequired, validate: { _ in return nil})
        self.isDefaultAddress = isDefaultAddress
        self.showCompanyField = showCompanyField
        self.isVerified = isVerified
        self.phoneNumberRequired = phoneNumberRequired
        self.stores = stores
        self.siteID = stores.sessionManager.defaultStoreID ?? Int64.min
        self.storageManager = storageManager

        // Set validation rules for fields that rely on instance properties.
        self.name.validate = { [weak self] newName in
            guard let self, self.company.value.isEmpty else {
                return nil
            }
            return newName.isEmpty ? Localization.Validation.nameOrCompany : nil
        }
        self.company.validate = { [weak self] newCompany in
            guard let self, self.name.value.isEmpty else {
                return nil
            }
            return newCompany.isEmpty ? Localization.Validation.nameOrCompany : nil
        }
        self.state.validate = { [weak self] newState in
            guard let self, stateRequired else {
                return nil
            }
            return newState.isEmpty ? Localization.Validation.state : nil
        }
        self.phone.validate = { [weak self] newPhone in
            guard let self else {
                return nil
            }
            return self.isPhoneNumberValid ? nil : Localization.Validation.phone
        }

        observeNameAndCompany()
        observeSelectedCountry()
        observeSelectedState()
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
                  isDefaultAddress: address.defaultAddress,
                  showCompanyField: address.company.isNotEmpty,
                  isVerified: address.isVerified,
                  phoneNumberRequired: true,
                  stores: stores,
                  storageManager: storageManager)
    }
}

// MARK: Validation

extension WooShippingEditAddressViewModel {
    /// Validate all fields in the address.
    func validateAddress() {
        allFields.forEach { $0.validateField() }
    }

    /// Validate the address field with the given type.
    func validate(_ field: WooShippingAddressFieldType) {
        allFields.first { $0.type == field }?.validateField()
    }

    /// Validates phone number for the address.
    /// This take into account whether phone is not empty,
    /// has length 10 with additional "1" area code for US.
    ///
    private var isPhoneNumberValid: Bool {
        guard phone.value.isNotEmpty else {
            return !phoneNumberRequired
        }
        guard isUSAddress else {
            return true
        }
        let phoneDigits = phone.value.components(separatedBy: .decimalDigits.inverted).joined()
        if phoneDigits.hasPrefix("1") {
            return phoneDigits.count == 11
        } else {
            return phoneDigits.count == 10
        }
    }
}

private extension WooShippingEditAddressViewModel {
    func observeNameAndCompany() {
        (name.$value.removeDuplicates()).combineLatest(company.$value.removeDuplicates())
            .sink { [weak self] name, company in
                guard let self else { return }
                self.name.required = company.isEmpty
                self.company.required = name.isEmpty
                self.name.validateField()
                self.company.validateField()
            }
            .store(in: &cancellables)
    }

    func observeSelectedCountry() {
        $selectedCountry
            .dropFirst()
            .sink { [weak self] selectedCountry in
                guard let self, let selectedCountry, self.selectedCountry != selectedCountry else { return }
                country.value = selectedCountry.code
                selectedState = nil
                state.required = stateRequired
            }
            .store(in: &cancellables)
    }

    func observeSelectedState() {
        $selectedState
            .dropFirst()
            .sink { [weak self] selectedState in
                guard let self else { return }
                state.value = selectedState?.code ?? ""
            }
            .store(in: &cancellables)
    }
}

// MARK: Remote
private extension WooShippingEditAddressViewModel {
    func fetchCountries() {
        refreshCountriesAndUpdateSelections()
        let action = DataAction.synchronizeCountries(siteID: siteID) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success:
                refreshCountriesAndUpdateSelections()
            case .failure:
                break
            }
        }

        stores.dispatch(action)
    }

    func refreshCountriesAndUpdateSelections() {
        try? resultsController.performFetch()
        // Updating the selected country clears the selected state.
        // We track the initial state code so we can set the correct selected state.
        let stateCode = state.value
        selectedCountry = countries.first { $0.code == country.value }
        selectedState = statesOfSelectedCountry.first { $0.code == stateCode }
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

private extension WooShippingEditAddressViewModel {
    enum Localization {
        enum Validation {
            static let nameOrCompany = NSLocalizedString("wooShipping.createLabels.editAddress.validation.nameOrCompany",
                                                         value: "Please provide a valid name or company name.",
                                                         comment: "Validation message when the name and company fields are empty " +
                                                         "in the Woo Shipping label creation flow")
            static let email = NSLocalizedString("wooShipping.createLabels.editAddress.validation.email",
                                                 value: "Please provide a valid email address.",
                                                 comment: "Validation message when the email field is empty in the Woo Shipping label creation flow")
            static let phone = NSLocalizedString("wooShipping.createLabels.editAddress.validation.phone",
                                                 value: "Please provide a valid phone number.",
                                                 comment: "Validation message when the phone field is empty in the Woo Shipping label creation flow")
            static let country = NSLocalizedString("wooShipping.createLabels.editAddress.validation.country",
                                                   value: "Please select a country.",
                                                   comment: "Validation message when the country field is empty in the Woo Shipping label creation flow")
            static let address = NSLocalizedString("wooShipping.createLabels.editAddress.validation.address",
                                                   value: "Please provide a valid address.",
                                                   comment: "Validation message when the address field is empty in the Woo Shipping label creation flow")
            static let city = NSLocalizedString("wooShipping.createLabels.editAddress.validation.city",
                                                value: "Please provide a valid city.",
                                                comment: "Validation message when the city field is empty in the Woo Shipping label creation flow")
            static let state = NSLocalizedString("wooShipping.createLabels.editAddress.validation.state",
                                                 value: "Please provide a valid state.",
                                                 comment: "Validation message when the state field is empty in the Woo Shipping label creation flow")
            static let postalCode = NSLocalizedString("wooShipping.createLabels.editAddress.validation.postalCode",
                                                      value: "Please provide a valid postal code.",
                                                      comment: "Validation message when the postal code field is empty in the Woo Shipping label creation flow")
        }
    }
}
