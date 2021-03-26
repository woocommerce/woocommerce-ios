import UIKit
import Yosemite

/// View model for `ShippingLabelPackageDetails`.
///
struct ShippingLabelPackageDetailsViewModel {

    let order: Order

    init(order: Order) {
        self.order = order
    }
}
