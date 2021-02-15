import UIKit
import Yosemite

final class ShippingLabelAddressValidationViewModel: NSObject {

    typealias Section = ShippingLabelAddressValidationViewController.Section
    typealias Row = ShippingLabelAddressValidationViewController.Row

    let addressVerification: ShippingLabelAddressVerification

    init(addressVerification: ShippingLabelAddressVerification) {
        self.addressVerification = addressVerification
    }

    var sections: [Section] {
        return [Section(rows: [.name, .company, .phones, .address, .address2, .city, .postcode, .state, .country])]
    }
}
