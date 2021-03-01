import UIKit
import Yosemite

final class ShippingLabelAddressFormViewModel: NSObject {

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
    private(set) var isAddressValidated: Bool = false

    private let stores: StoresManager

    /// Closure to notify the `ViewController` when the view model properties change.
    ///
    var onChange: (() -> (Void))?

    /// Current `ViewModel` state.
    ///
    private var state: State = State() {
        didSet {
            onChange?()
        }
    }

    var shouldShowTopBannerView: Bool {
        return addressValidationError?.generalError != nil
    }

    var showLoadingIndicator: Bool {
        return state.isLoading
    }

    init(siteID: Int64, type: ShipType, address: ShippingLabelAddress?, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.type = type
        self.address = address
        self.stores = stores
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

    var sections: [Section] {
        var rows: [Row] = [.name, .company, .phone, .address, .address2, .city, .postcode, .state, .country]
        if addressValidationError?.addressError != nil {
            if let addressIndex = rows.firstIndex(where: { $0 == .address }) {
                rows.insert(.fieldError, at: rows.index(after: addressIndex))
            }
        }
        else {
            rows.removeAll(where: { $0 == .fieldError })
        }
        return [Section(rows: rows)]
    }
}

// MARK: - Remote API
extension ShippingLabelAddressFormViewModel {
    func validateAddress(onSuccess: ((Bool, ShippingLabelAddressValidationError?) -> ())? = nil) {

        state.isLoading = true
        let addressToBeVerified = ShippingLabelAddressVerification(address: address, type: type)

        let action = ShippingLabelAction.validateAddress(siteID: siteID, address: addressToBeVerified) { [weak self] (result) in
            switch result {
            case .success:
                if (try? result.get().errors) == nil {
                    self?.isAddressValidated = true
                    self?.addressValidationError = nil
                    self?.state.isLoading = false
                    onSuccess?(true, nil)
                }
                else {
                    self?.isAddressValidated = false
                    self?.addressValidationError = try? result.get().errors
                    self?.state.isLoading = false
                    onSuccess?(false, try? result.get().errors)
                }
            case .failure(let error):
                DDLogError("⛔️ Error validating shipping label address: \(error)")
                self?.isAddressValidated = false
                self?.addressValidationError = ShippingLabelAddressValidationError(addressError: nil, generalError: error.localizedDescription)
                self?.state.isLoading = false
                onSuccess?(false, nil)
            }
        }
        stores.dispatch(action)
    }
}
