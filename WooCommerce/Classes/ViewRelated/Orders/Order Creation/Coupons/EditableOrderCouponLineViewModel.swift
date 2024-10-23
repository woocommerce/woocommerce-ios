import Foundation
import Yosemite
import Combine

final class EditableOrderCouponLineViewModel: ObservableObject {
    @Published private(set) var couponLineRows: [OrderCouponLine] = []

    private let orderSynchronizer: OrderSynchronizer

    init(orderSynchronizer: OrderSynchronizer) {
        self.orderSynchronizer = orderSynchronizer

        observeCouponsInOrder()
    }

    private func observeCouponsInOrder() {
        orderSynchronizer.orderPublisher
            .map { $0.coupons }
            .removeDuplicates()
            .assign(to: &$couponLineRows)
    }
}
