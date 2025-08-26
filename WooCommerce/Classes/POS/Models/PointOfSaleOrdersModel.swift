import Foundation
import Observation

@Observable final class PointOfSaleOrdersModel {
    let ordersController: PointOfSaleOrdersControllerProtocol

    init(ordersController: PointOfSaleOrdersControllerProtocol) {
        self.ordersController = ordersController
    }
}
