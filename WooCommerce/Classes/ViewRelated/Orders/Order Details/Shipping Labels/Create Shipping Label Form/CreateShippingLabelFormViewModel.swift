import UIKit
import Yosemite

/// Provides view data for Create Shipping Label, and handles init/UI/navigation actions needed.
///
final class CreateShippingLabelFormViewModel {

    typealias Section = CreateShippingLabelFormViewController.Section
    typealias Row = CreateShippingLabelFormViewController.Row

    private let order: Order

    init(order: Order) {
        self.order = order
    }

    var sections: [Section] {
        let rows: [Row] = [.shipFrom, .shipTo, .packageDetails, .shippingCarrierAndRates, .paymentMethod]
        return [Section(rows: rows)]
    }
}
