import UIKit
import Yosemite

final class ShippingLabelAddressFormViewModel: NSObject {

    typealias Section = ShippingLabelAddressFormViewController.Section
    typealias Row = ShippingLabelAddressFormViewController.Row

    let siteID: Int64
    let type: ShipType
    private(set) var address: ShippingLabelAddress?
    private(set) var addressValidationError: ShippingLabelAddressValidationError?
    private(set) var isAddressValidated: Bool = false

    private let stores: StoresManager

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

        let addressToBeVerified = ShippingLabelAddressVerification(address: address, type: type)

        let action = ShippingLabelAction.validateAddress(siteID: siteID, address: addressToBeVerified) { [weak self] (result) in
            switch result {
            case .success:
                if (try? result.get().errors) == nil {
                    self?.isAddressValidated = true
                    self?.addressValidationError = nil
                    onSuccess?(true, nil)
                }
                else {
                    self?.isAddressValidated = false
                    self?.addressValidationError = try? result.get().errors
                    onSuccess?(false, try? result.get().errors)
                }
            case .failure(let error):
                DDLogError("⛔️ Error validating shipping label address: \(error)")
                self?.isAddressValidated = false
                self?.addressValidationError = nil
                onSuccess?(false, nil)
            }
        }
        stores.dispatch(action)
    }
}
