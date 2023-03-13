import SwiftUI
import Yosemite

final class CouponLineDetailsViewModel: ObservableObject {

    /// Closure to be invoked when the coupon line is updated.
    ///
    var didSelectSave: ((OrderCouponLine?) -> Void)

    /// Stores the coupon code entered by the merchant.
    ///
    @Published var code: String = ""

    /// Returns true when existing coupon line is edited.
    ///
    let isExistingCouponLine: Bool

    /// Returns true when there are no valid pending changes.
    ///
    var shouldDisableDoneButton: Bool {
        guard !code.isEmpty else {
            return true
        }

        return code == initialCode
    }

    private let initialCode: String?

    init(isExistingCouponLine: Bool,
         code: String,
         didSelectSave: @escaping ((OrderCouponLine?) -> Void)) {
        self.isExistingCouponLine = isExistingCouponLine
        self.code = code
        self.initialCode = code
        self.didSelectSave = didSelectSave
    }

    func saveData() {
        let couponLine = OrderFactory.newOrderCouponLine(code: code)
        didSelectSave(couponLine)
    }
}
