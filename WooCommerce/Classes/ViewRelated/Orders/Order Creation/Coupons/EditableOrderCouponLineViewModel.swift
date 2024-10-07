import Foundation
import Yosemite
import Combine

final class EditableOrderCouponLineViewModel: ObservableObject {
    @Published private(set) var couponLineRows: [OrderCouponLine] = []

    private var orderSynchronizer: OrderSynchronizer

    init(orderSynchronizer: OrderSynchronizer) {
        self.orderSynchronizer = orderSynchronizer

        observeCouponsInOrder()
    }

    func observeCouponsInOrder() {
        orderSynchronizer.orderPublisher
            .map { $0.coupons }
            .removeDuplicates()
            .assign(to: &$couponLineRows)
    }

    func temporary_addCouponLine(_ input: OrderCouponLine) {
        couponLineRows.append(input)
    }

    func temporary_deleteCoupon() {
        couponLineRows.removeLast()
    }
}
