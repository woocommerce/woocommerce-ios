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
        let shipFrom = Row(type: .shipFrom, dataState: .validated, displayMode: .editable)
        let shipTo = Row(type: .shipTo, dataState: .pending, displayMode: .editable)
        let packageDetails = Row(type: .packageDetails, dataState: .pending, displayMode: .disabled)
        let shippingCarrierAndRates = Row(type: .shippingCarrierAndRates, dataState: .pending, displayMode: .disabled)
        let paymentMethod = Row(type: .paymentMethod, dataState: .pending, displayMode: .disabled)
        let rows: [Row] = [shipFrom, shipTo, packageDetails, shippingCarrierAndRates, paymentMethod]
        return [Section(rows: rows)]
    }
}
