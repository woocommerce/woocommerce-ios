import Foundation
import SwiftUI
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics
import Combine
import class WordPressShared.EmailFormatValidator

/// View model for editing an address in the Woo Shipping label flow.
final class WooShippingEditAddressViewModel: ObservableObject, Identifiable {
    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let debounceDelay: Double
    private let analytics: Analytics
    private var cancellables: Set<AnyCancellable> = []

    enum AddressType: Equatable {
        case origin
        case destination(orderID: Int64)
    }

    /// Type of address being edited.
    private let addressType: AddressType

    private var analyticAddressType: WooAnalyticsEvent.WooShipping.AddressType {
        switch addressType {
        case .origin: .origin
        case .destination: .destination
        }
    }

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
        switch addressType {
        case .origin:
            return true
        case .destination:
            return false
        }
    }

    /// Whether to show the company field by default.
    @Published var showCompanyField: Bool

    // MARK: Local requirements & validation

    /// Whether the original (unedited) address has been remotely verified.
    private var originalAddressIsVerified: Bool

    /// Whether the address is locally validated (there are no validation errors).
    @Published private var isValid: Bool = false

    /// Whether there are any local changes to the address fields.
    var hasChanges: Bool {
        allFields.contains { $0.hasChanges }
    }

    var allFields: [WooShippingAddressField] {
        [name, company, country, address, city, state, postalCode, email, phone]
    }

    /// The origin address country code.
    /// This is used to determine whether the phone number is required when editing a destination address.
    private let originCountryCode: String?

    /// The origin address state code.
    /// This is used to determine whether the phone number is required when editing a destination address.
    private let originStateCode: String?

    /// Status of the address, based on local validation and remote verification.
    var status: WooShippingAddressStatus {
        let isRemotelyVerified = originalAddressIsVerified && !hasChanges
        switch (isRemotelyVerified, isValid, canConfirmWithoutVerification) {
        case (true, true, _): // Is a valid, remotely verified address.
            return .verified
        case (false, true, _): // Is a valid, unverified address.
            return .unverified
        case (_, false, true): // Validation fails but user can proceed.
            return .unverified
        case (_, false, false): // Is an invalid address.
            return .missingInformation
        }
    }

    /// Label to describe the status of the address.
    var statusLabel: String {
        if let remoteValidationError, hasChanges {
            return remoteValidationError
        } else {
            return Localization.Status.label(for: status)
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

    /// Whether user can proceed with their input address even when validation fails.
    @Published private(set) var canConfirmWithoutVerification = false

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

    // MARK: Remote validation

    /// Whether a remote action is in progress.
    @Published private(set) var isLoading: Bool = false

    /// View model for normalizing the address.
    @Published var normalizeAddressVM: WooShippingNormalizeAddressViewModel?

    /// Error from remote validation, if any.
    @Published private var remoteValidationError: String?

    /// Current address update error alert state
    @Published var isShowingAddressErrorAlert = false
    private(set) var addressErrorState: AddressErrorState? = nil {
        didSet {
            isShowingAddressErrorAlert = addressErrorState != nil
        }
    }

    /// Closure called when an origin address is done being edited and the changes are confirmed.
    private(set) var onOriginAddressEdited: ((WooShippingOriginAddress) -> Void)?

    /// Closure called when a destination address is done being edited and the changes are confirmed.
    /// Returns the updated address and email address.
    private(set) var onDestinationAddressEdited: ((_ result: WooShippingDestinationAddressUpdate,
                                                   _ email: String?) -> Void)?

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
         originCountryCode: String? = nil,
         originStateCode: String? = nil,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         debounceDelayInSeconds: Double = 1,
         analytics: Analytics = ServiceLocator.analytics,
         onOriginAddressEdited: ((WooShippingOriginAddress) -> Void)? = nil,
         onDestinationAddressEdited: ((WooShippingDestinationAddressUpdate, String?) -> Void)? = nil) {
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
            (newEmail.isEmpty || !EmailFormatValidator.validate(string: newEmail)) ? Localization.Validation.email : nil
        })
        let phoneNumberRequired = Self.phoneNumberRequired(addressType: type,
                                                           selectedCountryCode: country,
                                                           selectedState: state,
                                                           originCountryCode: originCountryCode,
                                                           originStateCode: originStateCode)
        self.phone = WooShippingAddressField(type: .phone, value: phone, required: phoneNumberRequired, validate: { _ in return nil})
        self.isDefaultAddress = isDefaultAddress
        self.showCompanyField = showCompanyField
        self.originalAddressIsVerified = isVerified
        self.originCountryCode = originCountryCode
        self.originStateCode = originStateCode
        self.stores = stores
        self.siteID = stores.sessionManager.defaultStoreID ?? Int64.min
        self.storageManager = storageManager
        self.debounceDelay = debounceDelayInSeconds
        self.analytics = analytics
        self.onOriginAddressEdited = onOriginAddressEdited
        self.onDestinationAddressEdited = onDestinationAddressEdited
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

        observeFieldValues()
        observeNameAndCompany()
        observeSelectedCountry()
        observeSelectedState()
        observeFieldErrors()
        fetchCountries()
        validateAddress()

        analytics.track(event: .WooShipping.editingAddressStep(
            type: analyticAddressType,
            state: .started
        ))
    }

    /// Used to initialize the view model with an origin address.
    convenience init(address: WooShippingOriginAddress,
                     stores: StoresManager = ServiceLocator.stores,
                     storageManager: StorageManagerType = ServiceLocator.storageManager,
                     onAddressEdited: ((WooShippingOriginAddress) -> Void)? = nil) {
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
                  stores: stores,
                  storageManager: storageManager,
                  onOriginAddressEdited: onAddressEdited)
    }

    /// Used to initialize the view model with a destination address.
    convenience init(address: WooShippingAddress?,
                     orderID: Int64,
                     email: String?,
                     isVerified: Bool,
                     originCountryCode: String?,
                     originStateCode: String?,
                     stores: StoresManager = ServiceLocator.stores,
                     storageManager: StorageManagerType = ServiceLocator.storageManager,
                     onAddressEdited: ((WooShippingDestinationAddressUpdate, String?) -> Void)? = nil) {
        self.init(type: .destination(orderID: orderID),
                  id: UUID().uuidString,
                  name: address?.name ?? "",
                  company: address?.company ?? "",
                  country: address?.country ?? "",
                  address: address?.combinedAddress ?? "",
                  city: address?.city ?? "",
                  state: address?.state ?? "",
                  postalCode: address?.postcode ?? "",
                  email: email ?? "",
                  phone: address?.phone ?? "",
                  isDefaultAddress: false,
                  showCompanyField: address?.company.isNotEmpty == true,
                  isVerified: isVerified,
                  originCountryCode: originCountryCode,
                  originStateCode: originStateCode,
                  stores: stores,
                  storageManager: storageManager,
                  onDestinationAddressEdited: onAddressEdited)
    }

    func proceedWithInputAddress() {
        let address = WooShippingAddress(company: company.value,
                                         name: name.value,
                                         email: email.value,
                                         phone: phone.value,
                                         country: country.value,
                                         state: state.value,
                                         address1: address.value,
                                         address2: "",
                                         city: city.value,
                                         postcode: postalCode.value)
        updateConfirmedAddress(address, withoutVerification: true)
    }

    /// Validates the address remotely.
    @MainActor
    func remotelyValidateAddress() async {
        let addressToValidate = WooShippingAddress(company: company.value,
                                                   name: name.value,
                                                   email: email.value,
                                                   phone: phone.value,
                                                   country: country.value,
                                                   state: state.value,
                                                   address1: address.value,
                                                   address2: "",
                                                   city: city.value,
                                                   postcode: postalCode.value)
        do {
            let validation = try await remotelyValidateAddress(addressToValidate)
            analytics.track(event: .WooShipping.editingAddressStep(
                type: analyticAddressType,
                state: .validationSuccess
            ))
            normalizeAddressVM = WooShippingNormalizeAddressViewModel(enteredAddress: validation.originalAddress,
                                                                      suggestedAddress: validation.normalizedAddress.toWooShippingAddress(),
                                                                      onConfirm: { [weak self] confirmedAddress in
                guard let self else { return }
                updateConfirmedAddress(confirmedAddress)
            })
        } catch let error as WooShippingAddressValidationError {
            /// Enables proceeding for destination addresses even when validation fails
            if case .destination = addressType {
                canConfirmWithoutVerification = true
            }
            if let nameError = error.nameError {
                name.setError(nameError)
            }
            if let addressError = error.addressError {
                address.setError(addressError)
            }
            if let generalError = error.generalError {
                remoteValidationError = generalError
            }
            analytics.track(event: .WooShipping.editingAddressStep(
                type: analyticAddressType,
                state: .validationFailed,
                error: error
            ))
        } catch {
            DDLogError("⛔️ Error validating address for Woo Shipping label: \(error)")

            // Show error alert when validation request fails
            addressErrorState = .validation

            analytics.track(event: .WooShipping.editingAddressStep(
                type: analyticAddressType,
                state: .validationFailed,
                error: error
            ))
        }
    }

    /// Update confirmed address remotely.
    func updateConfirmedAddress(_ address: WooShippingAddress, withoutVerification: Bool = false) {
        switch addressType {
        case .origin:
            updateConfirmedOriginAddress(address)
        case .destination(let orderID):
            updateConfirmedDestinationAddress(
                for: orderID,
                with: address,
                withoutVerification: withoutVerification
            )
        }
    }

    /// Updates the origin address remotely with the provided (normalized) address and other edits.
    private func updateConfirmedOriginAddress(_ address: WooShippingAddress) {
        guard case .origin = addressType else {
            return
        }

        // Merge the provided (normalized) address with the edited address fields.
        let originAddress = WooShippingOriginAddress(siteID: siteID,
                                                     id: id,
                                                     company: address.company,
                                                     address1: address.address1,
                                                     address2: address.address2,
                                                     city: address.city,
                                                     state: address.state,
                                                     postcode: address.postcode,
                                                     country: address.country,
                                                     phone: address.phone,
                                                     firstName: name.value,
                                                     lastName: "",
                                                     email: email.value,
                                                     defaultAddress: isDefaultAddress,
                                                     isVerified: true)

        Task { @MainActor in
            do {
                let updatedOriginAddress = try await updateOriginAddress(with: originAddress)
                onOriginAddressEdited?(updatedOriginAddress)
                analytics.track(event: .WooShipping.editingAddressStep(type: .origin, state: .confirmed))
            } catch {
                DDLogError("⛔️ Error updating origin address for Woo Shipping label: \(error)")

                // Show error alert when origin address update fails
                addressErrorState = .updateOrigin(address)

                analytics.track(event: .WooShipping.editingAddressStep(
                    type: .origin,
                    state: .confirmed,
                    error: error
                ))
            }
        }
    }

    /// Updates the destination address remotely with the provided (normalized) address and other edits.
    private func updateConfirmedDestinationAddress(for orderID: Int64,
                                                   with address: WooShippingAddress,
                                                   withoutVerification: Bool) {
        // Merge the provided (normalized) address with the edited address fields.
        let destinationAddress = WooShippingDestinationAddress(company: address.company,
                                                    address1: address.address1,
                                                    address2: address.address2,
                                                    city: address.city,
                                                    state: address.state,
                                                    postcode: address.postcode,
                                                    country: address.country,
                                                    phone: address.phone,
                                                    name: address.name,
                                                    firstName: "",
                                                    lastName: "",
                                                    email: email.value)

        Task { @MainActor in
            do {
                let result = try await updateDestinationAddress(
                    for: orderID,
                    with: destinationAddress,
                    isVerified: !withoutVerification
                )
                onDestinationAddressEdited?(result, email.value)
                analytics.track(event: .WooShipping.editingAddressStep(
                    type: .destination,
                    state: withoutVerification ? .confirmedWithoutVerification : .confirmed
                ))
            } catch {
                DDLogError("⛔️ Error updating destination address for Woo Shipping label: \(error)")

                // Show error alert when destination address update fails
                addressErrorState = .updateDestination(address)

                analytics.track(event: .WooShipping.editingAddressStep(
                    type: .destination,
                    state: withoutVerification ? .confirmedWithoutVerification : .confirmed,
                    error: error
                ))
            }
        }
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
            return !phoneNumberRequired(for: country.value, and: state.value)
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

    /// Whether the phone number is required.
    ///
    private func phoneNumberRequired(for country: String?, and state: String?) -> Bool {
        Self.phoneNumberRequired(addressType: addressType,
                                    selectedCountryCode: country,
                                    selectedState: state,
                                    originCountryCode: originCountryCode,
                                    originStateCode: originStateCode)
    }

    /// Whether the phone number is required.
    /// - Parameters:
    ///   - addressType: Type of address being edited.
    ///   - selectedCountryCode: Country code of the selected country for the address being edited.
    ///   - selectedState: Selected state for the address being edited.
    ///   - originCountryCode: Country code of the origin address.
    ///   - originStateCode: State code of the origin address.
    private static func phoneNumberRequired(addressType: AddressType,
                                            selectedCountryCode: String?,
                                            selectedState: String?,
                                            originCountryCode: String?,
                                            originStateCode: String?) -> Bool {
        switch addressType {
        case .origin:
            return true
        case .destination:
            return WooShippingCustomsRequirements.isCustomsRequired(originCountry: originCountryCode,
                                                                    originState: originStateCode,
                                                                    destinationCountry: selectedCountryCode,
                                                                    destinationState: selectedState)
        }
    }
}

private extension WooShippingEditAddressViewModel {
    func observeNameAndCompany() {
        let nameValues = name.$value.removeDuplicates()
        let companyValues = company.$value.removeDuplicates()

        (nameValues).combineLatest(companyValues)
            .sink { [weak self] _, _ in
                guard let self else { return }
                self.name.clearError()
                self.company.clearError()
            }
            .store(in: &cancellables)

        (nameValues).combineLatest(companyValues)
            .debounce(for: .seconds(debounceDelay), scheduler: DispatchQueue.main)
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
                country.setDisplayValue(selectedCountry.name)
                selectedState = nil
                state.required = stateRequired

                // Update phone number requirement based on selected country.
                phone.required = phoneNumberRequired(for: selectedCountry.code, and: selectedState?.code)
                phone.validateField()
            }
            .store(in: &cancellables)
    }

    func observeSelectedState() {
        $selectedState
            .dropFirst()
            .sink { [weak self] selectedState in
                guard let self else { return }
                state.value = selectedState?.code ?? ""
                state.setDisplayValue(selectedState?.name ?? "")

                // Update phone number requirement based on selected state.
                phone.required = phoneNumberRequired(for: country.value, and: selectedState?.code)
                phone.validateField()
            }
            .store(in: &cancellables)
    }

    func observeFieldErrors() {
        allFields.map { $0.$errorMessage }
            .combineLatest()
            .sink { [weak self] errors in
                guard let self else { return }
                isValid = errors.allSatisfy { $0 == nil }
            }
            .store(in: &cancellables)
    }

    func observeFieldValues() {
        allFields.map { $0.$value.removeDuplicates() }
            .combineLatest()
            .map { _ in false }
            .assign(to: &$canConfirmWithoutVerification)
    }
}

// MARK: Remote
private extension WooShippingEditAddressViewModel {
    func fetchCountries() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.refreshCountriesAndUpdateSelections()
        }

        resultsController.onDidResetContent = { [weak self] in
            self?.refreshCountriesAndUpdateSelections()
        }

        try? resultsController.performFetch()
        refreshCountriesAndUpdateSelections()
    }

    func refreshCountriesAndUpdateSelections() {
        // Updating the selected country clears the selected state.
        // We track the initial state code so we can set the correct selected state.
        let stateCode = state.value
        selectedCountry = countries.first { $0.code == country.value }
        selectedState = statesOfSelectedCountry.first { $0.code == stateCode }
    }

    /// Remotely validates the provided address.
    @MainActor
    func remotelyValidateAddress(_ address: WooShippingAddress) async throws -> WooShippingAddressValidationSuccess {
        try await withCheckedThrowingContinuation { continuation in
            isLoading = true
            let action = WooShippingAction.validateAddress(siteID: siteID,
                                                           address: address) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(validation):
                    continuation.resume(returning: validation)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
                isLoading = false
            }
            stores.dispatch(action)
        }
    }

    /// Updates an origin address remotely.
    @MainActor
    func updateOriginAddress(with address: WooShippingOriginAddress) async throws -> WooShippingOriginAddress {
        return try await withCheckedThrowingContinuation { continuation in
            isLoading = true
            let action = WooShippingAction.updateOriginAddress(siteID: siteID,
                                                               address: address,
                                                               isVerified: address.isVerified) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(result):
                    continuation.resume(returning: result.address)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
                isLoading = false
            }
            stores.dispatch(action)
        }
    }

    /// Updates a destination address remotely.
    @MainActor
    func updateDestinationAddress(for orderID: Int64,
                                  with address: WooShippingDestinationAddress,
                                  isVerified: Bool) async throws -> WooShippingDestinationAddressUpdate {
        return try await withCheckedThrowingContinuation { continuation in
            isLoading = true
            let action = WooShippingAction.updateDestinationAddress(siteID: siteID,
                                                                    orderID: orderID,
                                                                    address: address,
                                                                    isVerified: isVerified) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(result):
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
                isLoading = false
            }
            stores.dispatch(action)
        }
    }
}

// MARK: Address update error handling
extension WooShippingEditAddressViewModel {
    enum AddressErrorState: Equatable {
        case validation

        /// Associated address is used for retrying updating attempt
        case updateOrigin(WooShippingAddress)
        case updateDestination(WooShippingAddress)

        var title: String {
            switch self {
            case .validation:
                return Localization.AddressValidationError.title
            case .updateOrigin:
                return Localization.OriginAddressUpdateError.title
            case .updateDestination:
                return Localization.DestinationAddressUpdateError.title
            }
        }

        var message: String {
            switch self {
            case .validation:
                return Localization.AddressValidationError.message
            case .updateOrigin:
                return Localization.OriginAddressUpdateError.message
            case .updateDestination:
                return Localization.DestinationAddressUpdateError.message
            }
        }
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

        enum Status {
            static func label(for status: WooShippingAddressStatus) -> String {
                switch status {
                case .verified:
                    return verified
                case .unverified:
                    return unverified
                case .missingInformation:
                    return missingInformation
                }
            }
            static let verified = NSLocalizedString("wooShipping.createLabels.editAddress.verified",
                                                    value: "Address verified",
                                                    comment: "Label when the address has been verified in the Woo Shipping label creation flow")
            static let unverified = NSLocalizedString("wooShipping.createLabels.editAddress.unverified",
                                                      value: "Unverified address",
                                                      comment: "Label when the address is unverified in the Woo Shipping label creation flow")
            static let missingInformation = NSLocalizedString("wooShipping.createLabels.editAddress.missingInformation",
                                                              value: "Missing information",
                                                              comment: "Label when the address is missing information in the Woo Shipping label creation flow")
        }

        enum AddressValidationError {
            static let title = NSLocalizedString(
                "wooShipping.createLabels.editAddress.validation.addressValidationError.title",
                value: "Address Validation Error",
                comment: "Title for the address validation error alert in the Woo Shipping label creation flow"
            )

            static let message = NSLocalizedString(
                "wooShipping.createLabels.editAddress.validation.addressValidationError.message",
                value: "The address you entered could not be verified. Please try again later.",
                comment: "Message for the address validation error alert in the Woo Shipping label creation flow"
            )
        }

        enum OriginAddressUpdateError {
            static let title = NSLocalizedString(
                "wooShipping.createLabels.editAddress.validation.originAddressUpdateError.title",
                value: "Origin Address Update Error",
                comment: "Title for the origin address update error alert in the Woo Shipping label creation flow"
            )

            static let message = NSLocalizedString(
                "wooShipping.createLabels.editAddress.validation.originAddressUpdateError.message",
                value: "The origin address could not be updated. Please try again later.",
                comment: "Message for the origin address update error alert in the Woo Shipping label creation flow"
            )
        }

        enum DestinationAddressUpdateError {
            static let title = NSLocalizedString(
                "wooShipping.createLabels.editAddress.validation.destinationAddressUpdateError.title",
                value: "Destination Address Update Error",
                comment: "Title for the destination address update error alert in the Woo Shipping label creation flow"
            )

            static let message = NSLocalizedString(
                "wooShipping.createLabels.editAddress.validation.destinationAddressUpdateError.message",
                value: "The destination address could not be updated. Please try again later.",
                comment: "Message for the destination address update error alert in the Woo Shipping label creation flow"
            )
        }
    }
}
