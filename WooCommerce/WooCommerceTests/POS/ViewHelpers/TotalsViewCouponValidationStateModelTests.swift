import Foundation
import Testing
@testable import WooCommerce

struct TotalsViewCouponValidationStateModelTests {
    @available(iOS 17.0, *)
    @Test func test_init_returns_nil_when_cart_is_empty() {
        let mockModel = MockPointOfSaleAggregateModel()
        mockModel.cart = Cart()

        let model = TotalsViewCouponValidationStateModel(posModel: mockModel)

        #expect(model == nil)
    }

    @available(iOS 17.0, *)
    @Test func test_showsCouponValidation_returns_false_when_order_not_syncing() {
        let mockModel = MockPointOfSaleAggregateModel()
        var cart = Cart()
        cart.add(.coupon(.init(id: .init(), code: "TEST10", summary: "")))
        mockModel.cart = cart
        mockModel.orderState = .idle

        let model = TotalsViewCouponValidationStateModel(posModel: mockModel)

        #expect(model?.showsCouponValidation == false)
    }

    @available(iOS 17.0, *)
    @Test func test_showsCouponValidation_returns_true_when_cart_has_coupons_and_order_syncing() {
        let mockModel = MockPointOfSaleAggregateModel()
        var cart = Cart()
        cart.add(.coupon(.init(id: .init(), code: "TEST10", summary: "")))
        mockModel.cart = cart
        mockModel.orderState = .syncing

        let model = TotalsViewCouponValidationStateModel(posModel: mockModel)

        #expect(model?.showsCouponValidation == true)
    }
}
