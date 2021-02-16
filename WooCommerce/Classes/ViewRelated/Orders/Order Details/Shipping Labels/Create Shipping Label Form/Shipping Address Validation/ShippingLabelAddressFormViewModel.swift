import UIKit
import Yosemite

final class ShippingLabelAddressFormViewModel: NSObject {

    typealias Section = ShippingLabelAddressFormViewController.Section
    typealias Row = ShippingLabelAddressFormViewController.Row

    let type: ShipType
    let address: ShippingLabelAddress?

    init(type: ShipType, address: ShippingLabelAddress?) {
        self.type = type
        self.address = address
    }

    var sections: [Section] {
        return [Section(rows: [.name, .company, .phone, .address, .address2, .city, .postcode, .state, .country])]
    }
}
