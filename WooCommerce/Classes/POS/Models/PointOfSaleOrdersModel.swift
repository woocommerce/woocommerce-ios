import Foundation
import Observation

protocol PointOfSaleOrdersModelProtocol {
    var ordersController: PointOfSaleOrdersControllerProtocol { get }
}

@Observable final class PointOfSaleOrdersModel: PointOfSaleOrdersModelProtocol {
    let ordersController: PointOfSaleOrdersControllerProtocol

    init(ordersController: PointOfSaleOrdersControllerProtocol) {
        self.ordersController = ordersController
    }
}
