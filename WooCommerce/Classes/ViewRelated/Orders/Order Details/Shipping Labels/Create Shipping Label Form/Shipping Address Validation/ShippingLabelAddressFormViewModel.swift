import Combine
import UIKit
import Yosemite

final class ShippingLabelAddressFormViewModel {

    /// Defines the necessary state to produce the ViewModel's outputs.
    ///
    fileprivate struct State {

        /// Indicates if the view model is validating an address
        ///
        var isLoading: Bool = false
    }

    typealias Section = ShippingLabelAddressFormViewController.Section
    typealias Row = ShippingLabelAddressFormViewController.Row

    let siteID: Int64
    let type: ShipType
    private(set) var address: ShippingLabelAddress?
    private(set) var addressValidationError: ShippingLabelAddressValidationError?
    private(set) var addressValidated: Validation = .none
    private(set) var phoneNumberRequired: Bool
    private(set) var email: String?

    private let stores: StoresManager

    /// Closure to notify the `ViewController` when the view model properties change.
    /// Accepts optional index for row to be focused after reloading the table view.
    ///
    var onChange: ((_ focusedRowIndex: Int?) -> (Void))?

    /// Current `ViewModel` state.
    ///
    private var state: State = State() {
        didSet {
            updateSections()
            onChange?(nil)
        }
    }

    var shouldShowTopBannerView: Bool {
        return addressValidationError?.generalError != nil
    }

    var showLoadingIndicator: Bool {
        return state.isLoading
    }

    var isUSAddress: Bool {
        address?.country == "US"
    }

    var sections: [Section] = []

    private(set) var countries: [Country]

    var nameRequired: Bool {
        address?.company.isEmpty == true
    }

    var statesOfSelectedCountry: [StateOfACountry] {
        countries.first { $0.code == address?.country }?.states.sorted { $0.name < $1.name } ?? []
    }

    var stateOfCountryRequired: Bool {
        statesOfSelectedCountry.isNotEmpty
    }

    var extendedCountryName: String? {
        return countries.first { $0.code == address?.country }?.name
    }

    var extendedStateName: String? {
        return statesOfSelectedCountry.first { $0.code == address?.state }?.name
    }

    private let localErrors = CurrentValueSubject<[ValidationError], Never>([])
    private let currentRow = CurrentValueSubject<Row?, Never>(nil)
    private var validationSubscription: AnyCancellable?

    init(
        siteID: Int64,
        type: ShipType,
        address: ShippingLabelAddress?,
        email: String?,
        phoneNumberRequired: Bool = false,
        stores: StoresManager = ServiceLocator.stores,
        validationError: ShippingLabelAddressValidationError?,
        countries: [Country]
    ) {
        self.siteID = siteID
        self.type = type
        self.address = address
        self.email = email
        self.phoneNumberRequired = phoneNumberRequired
        self.stores = stores
        if let validationError = validationError {
            addressValidationError = validationError
            addressValidated = .remote
        }
        self.countries = countries
        updateSections()
        configureValidationError()
    }

    func handleAddressValueChanges(row: Row, newValue: String?) {
        switch row {
        case .name:
            address = address?.copy(name: newValue)
        case .company:
            address = address?.copy(company: newValue)
        case .phone:
            address = address?.copy(phone: newValue)
        case .address:
            address = address?.copy(address1: newValue)
        case .address2:
            address = address?.copy(address2: newValue)
        case .city:
            address = address?.copy(city: newValue)
        case .postcode:
            address = address?.copy(postcode: newValue)
        case .state:
            address = address?.copy(state: newValue)
        case .country:
            address = address?.copy(country: newValue, state: "")
        default:
            return
        }

        currentRow.send(row)
        localErrors.send(validateAddressLocally())
    }

    func updateSections() {
        var rows: [Row] = [.name, .company, .phone, .address, .address2, .city, .postcode, .state, .country]

        let localErrors = validateAddressLocally()

        if localErrors.contains(.name) {
            if let index = rows.firstIndex(where: { $0 == .name }) {
                rows.insert(.fieldError(.name), at: rows.index(after: index))
            }
        }
        if addressValidationError?.addressError != nil || localErrors.contains(.address) {
            if let index = rows.firstIndex(where: { $0 == .address }) {
                rows.insert(.fieldError(.address), at: rows.index(after: index))
            }
        }
        if localErrors.contains(.city) {
            if let index = rows.firstIndex(where: { $0 == .city }) {
                rows.insert(.fieldError(.city), at: rows.index(after: index))
            }
        }
        if localErrors.contains(.postcode) {
            if let index = rows.firstIndex(where: { $0 == .postcode }) {
                rows.insert(.fieldError(.postcode), at: rows.index(after: index))
            }
        }
        if localErrors.contains(.state) {
            if let index = rows.firstIndex(where: { $0 == .state }) {
                rows.insert(.fieldError(.state), at: rows.index(after: index))
            }
        }
        if localErrors.contains(.country) {
            if let index = rows.firstIndex(where: { $0 == .country }) {
                rows.insert(.fieldError(.country), at: rows.index(after: index))
            }
        }
        if localErrors.contains(.missingPhoneNumber) {
            if let index = rows.firstIndex(where: { $0 == .phone }) {
                rows.insert(.fieldError(.missingPhoneNumber), at: rows.index(after: index))
            }
        } else if localErrors.contains(.invalidPhoneNumber) {
            if let index = rows.firstIndex(where: { $0 == .phone }) {
                rows.insert(.fieldError(.invalidPhoneNumber), at: rows.index(after: index))
            }
        }
        sections = [Section(rows: rows)]
    }
}

// MARK: - Local Validation
extension ShippingLabelAddressFormViewModel {

    // Defines if the address was not validated, or validated locally/remotely.
    enum Validation {
        case none
        case local
        case remote
    }

    enum ValidationError {
        case name
        case address
        case city
        case postcode
        case state
        case country
        case missingPhoneNumber
        case invalidPhoneNumber
    }

    /// Triggers reloading table view if there's a change in local errors.
    ///
    private func configureValidationError() {
        validationSubscription = localErrors
            .removeDuplicates()
            .withLatestFrom(currentRow)
            .sink { [weak self] _, row in
                guard let self = self else { return }
                self.updateSections()
                let index: Int? = self.sections.first?.rows.firstIndex(where: { $0 == row })
                self.onChange?(index)
            }

        // Append any initial local error.
        localErrors.send(validateAddressLocally())
    }

    /// Validates phone number for the address.
    /// This take into account whether phone is not empty,
    /// has length 10 with additional "1" area code for US.
    ///
    private var isPhoneNumberValid: Bool {
        guard let phone = address?.phone, phone.isNotEmpty else {
            return false
        }
        guard isUSAddress else {
            return true
        }
        if phone.hasPrefix("1") {
            return phone.count == 11
        } else {
            return phone.count == 10
        }
    }

    private var phoneValidationError: ValidationError? {
        guard let addressToBeValidated = address else {
            return nil
        }
        if phoneNumberRequired {
            if addressToBeValidated.phone.isEmpty {
                return .missingPhoneNumber
            } else if !isPhoneNumberValid {
                return .invalidPhoneNumber
            }
        }
        return nil
    }

    private func validateAddressLocally() -> [ValidationError] {
        var errors: [ValidationError] = []

        if let addressToBeValidated = address {
            if addressToBeValidated.name.isEmpty && nameRequired {
                errors.append(.name)
            }
            if addressToBeValidated.address1.isEmpty {
                errors.append(.address)
            }
            if addressToBeValidated.city.isEmpty {
                errors.append(.city)
            }
            if addressToBeValidated.postcode.isEmpty {
                errors.append(.postcode)
            }
            if addressToBeValidated.state.isEmpty && stateOfCountryRequired {
                errors.append(.state)
            }
            if addressToBeValidated.country.isEmpty {
                errors.append(.country)
            }
            if let error = phoneValidationError {
                errors.append(error)
            }
        }

        return errors
    }
}

// MARK: - Remote Validation API
extension ShippingLabelAddressFormViewModel {

    enum AddressValidationError: Error {
        case none
        case remote(ShippingLabelAddressValidationError?)
    }

    /// Validate the address locally and remotely. If `onlyLocally` is equal `true`, the validation will happens just locally.
    ///
    func validateAddress(onlyLocally: Bool, completion: @escaping (Result<Void, AddressValidationError>) -> Void) {

        addressValidationError = nil
        if validateAddressLocally().isNotEmpty {
            addressValidated = .none
            state.isLoading = false
            completion(.failure(.none))
            return
        }
        addressValidated = .local

        if onlyLocally {
            completion(.success(()))
            return
        }

        state.isLoading = true
        let addressToBeVerified = ShippingLabelAddressVerification(address: address, type: type)
        let action = ShippingLabelAction.validateAddress(siteID: siteID, address: addressToBeVerified) { [weak self] (result) in
            switch result {
            case .success:
                ServiceLocator.analytics.track(.shippingLabelAddressValidationSucceeded)
                self?.addressValidated = .remote
                self?.addressValidationError = nil
                self?.state.isLoading = false
                completion(.success(()))
            case .failure(let error as ShippingLabelAddressValidationError):
                ServiceLocator.analytics.track(.shippingLabelAddressValidationFailed, withProperties: ["error": error.localizedDescription])
                self?.addressValidated = .none
                self?.addressValidationError = error
                self?.state.isLoading = false
                completion(.failure(.remote(error)))
            case .failure(let error):
                ServiceLocator.analytics.track(.shippingLabelAddressValidationFailed, withProperties: ["error": error.localizedDescription])
                DDLogError("⛔️ Error validating shipping label address: \(error)")
                self?.addressValidated = .none
                self?.addressValidationError = ShippingLabelAddressValidationError(addressError: nil, generalError: error.localizedDescription)
                self?.state.isLoading = false
                completion(.failure(.none))
            }
        }
        stores.dispatch(action)
    }
}
