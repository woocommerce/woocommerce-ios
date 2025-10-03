import Foundation
@testable import Yosemite
import Networking

final class MockOrderStoreMethods: OrderStoreMethodsProtocol {
    var deleteOrderCalled = false
    var deletedOrder: Order?
    var deletedSiteID: Int64?
    var deletedPermanently: Bool?
    var deleteOrderResult: Result<Order, Error> = .success(Order.fake())

    func deleteOrder(siteID: Int64,
                     order: Order,
                     deletePermanently: Bool,
                     onCompletion: @escaping (Result<Order, Error>) -> Void) {
        deleteOrderCalled = true
        deletedOrder = order
        deletedSiteID = siteID
        deletedPermanently = deletePermanently
        onCompletion(deleteOrderResult)
    }
}
