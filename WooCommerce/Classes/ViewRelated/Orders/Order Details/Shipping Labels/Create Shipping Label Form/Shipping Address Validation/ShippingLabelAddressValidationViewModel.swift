import UIKit
import Yosemite

final class ShippingLabelAddressValidationViewModel: NSObject {

    let addressVerification: ShippingLabelAddressVerification

    init(addressVerification: ShippingLabelAddressVerification) {
        self.addressVerification = addressVerification
    }

}
