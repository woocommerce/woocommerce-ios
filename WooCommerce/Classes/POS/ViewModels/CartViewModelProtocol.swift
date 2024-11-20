import SwiftUI
import Combine
import protocol Yosemite.POSItem

protocol CartViewModelProtocol: ObservableObject {
    var itemsInCartLabel: String? { get }

    func shouldPreventCartEditing(orderState: PointOfSaleOrderState,
                                  paymentState: PointOfSalePaymentState) -> Bool
}
