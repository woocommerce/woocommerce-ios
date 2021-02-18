import UIKit
import Yosemite

final class ShippingLabelAddressFormViewModel: NSObject {

    typealias Section = ShippingLabelAddressFormViewController.Section
    typealias Row = ShippingLabelAddressFormViewController.Row

    let type: ShipType
    private (set) var address: ShippingLabelAddress?

    init(type: ShipType, address: ShippingLabelAddress?) {
        self.type = type
        self.address = address
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
