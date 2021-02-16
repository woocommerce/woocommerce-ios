import UIKit
import Yosemite

final class ShippingLabelAddressFormViewModel: NSObject {

    typealias Section = ShippingLabelAddressFormViewController.Section
    typealias Row = ShippingLabelAddressFormViewController.Row

    let addressVerification: ShippingLabelAddressVerification

    init(addressVerification: ShippingLabelAddressVerification) {
        self.addressVerification = addressVerification
    }

    var sections: [Section] {
        return [Section(rows: [.name, .company, .phones, .address, .address2, .city, .postcode, .state, .country])]
    }
}
