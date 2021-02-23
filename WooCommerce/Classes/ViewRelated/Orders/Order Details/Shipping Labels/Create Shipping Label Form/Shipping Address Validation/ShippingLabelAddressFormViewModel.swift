import UIKit
import Yosemite

final class ShippingLabelAddressFormViewModel: NSObject {

    typealias Section = ShippingLabelAddressFormViewController.Section
    typealias Row = ShippingLabelAddressFormViewController.Row

    let siteID: Int64
    let type: ShipType
    private (set) var address: ShippingLabelAddress?

    private let stores: StoresManager
    private var addressIsValidated: Bool = false

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
        return [Section(rows: [.name, .company, .phone, .address, .address2, .city, .postcode, .state, .country])]
    }
}

// MARK: - Remote API
extension ShippingLabelAddressFormViewModel {
    func validateAddress(onSuccess: ((Bool, Error?) -> ())? = nil) {

        let addressToBeVerified = ShippingLabelAddressVerification(address: address, type: type)

        let action = ShippingLabelAction.validateAddress(siteID: siteID, address: addressToBeVerified) { [weak self] (result) in
            switch result {
            case .success:
                self?.addressIsValidated = true
                onSuccess?(true, nil)
            case .failure(let error):
                DDLogError("⛔️ Error validating shipping label address: \(error)")
                self?.addressIsValidated = false
                onSuccess?(false, error)
            }
        }
        stores.dispatch(action)
    }
}
