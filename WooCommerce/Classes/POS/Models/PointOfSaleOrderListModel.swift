import Foundation
import Observation

@Observable final class PointOfSaleOrderListModel {
    let ordersController: PointOfSaleOrderListControllerProtocol

    init(ordersController: PointOfSaleOrderListControllerProtocol) {
        self.ordersController = ordersController
    }
}
