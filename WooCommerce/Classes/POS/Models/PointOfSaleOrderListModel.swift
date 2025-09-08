import Foundation
import Observation

@Observable final class PointOfSaleOrderListModel {
    let ordersController: PointOfSaleSearchingOrderListControllerProtocol

    init(ordersController: PointOfSaleSearchingOrderListControllerProtocol) {
        self.ordersController = ordersController
    }
}
