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

    private let stores: StoresManager

    /// Closure to notify the `ViewController` when the view model properties change.
    ///
    var onChange: (() -> (Void))?

    /// Current `ViewModel` state.
    ///
    private var state: State = State() {
        didSet {
            updateSections()
            onChange?()
        }
    }

    var shouldShowTopBannerView: Bool {
        return addressValidationError?.generalError != nil
    }

    var showLoadingIndicator: Bool {
        return state.isLoading
    }

    var sections: [Section] = []

    init(siteID: Int64, type: ShipType, address: ShippingLabelAddress?, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.type = type
        self.address = address
        self.stores = stores
        updateSections()
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
            address = address?.copy(country: newValue)
        default:
            return
        }
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
    }

    private func validateAddressLocally() -> [ValidationError] {
        var errors: [ValidationError] = []

        if let addressToBeValidated = address {
            if addressToBeValidated.name.isEmpty {
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
            if addressToBeValidated.state.isEmpty {
                errors.append(.state)
            }
            if addressToBeValidated.country.isEmpty {
                errors.append(.country)
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
                if (try? result.get().errors) == nil {
                    self?.addressValidated = .remote
                    self?.addressValidationError = nil
                    self?.state.isLoading = false
                    completion(.success(()))
                }
                else {
                    self?.addressValidated = .none
                    self?.addressValidationError = try? result.get().errors
                    self?.state.isLoading = false
                    completion(.failure(.remote(try? result.get().errors)))
                }
            case .failure(let error):
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
