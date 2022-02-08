import XCTest
@testable import Yosemite
@testable import WooCommerce

final class CouponDetailsViewModelTests: XCTestCase {

    func test_coupon_details_are_correct_for_fixedProduct_discount_type() {
        // Given
        let sampleCoupon = Coupon.fake().copy(
            code: "AGK32FD",
            amount: "10.00",
            discountType: .fixedProduct,
            description: "Coupon description",
            dateExpires: Date(timeIntervalSince1970: 1642755825), // GMT: January 21, 2022
            productIds: []
        )
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.couponCode, "AGK32FD")
        XCTAssertEqual(viewModel.amount, "$10.00")
        XCTAssertEqual(viewModel.description, "Coupon description")
        XCTAssertEqual(viewModel.expiryDate, "January 21, 2022")
    }

    func test_coupon_details_are_correct_for_percentage_discount_type() {
        // Given
        let sampleCoupon = Coupon.fake().copy(
            code: "AGK32FD",
            amount: "10.00",
            discountType: .percent,
            description: "Coupon description",
            dateExpires: Date(timeIntervalSince1970: 1642755825), // GMT: January 21, 2022
            productIds: []
        )
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        XCTAssertEqual(viewModel.couponCode, "AGK32FD")
        XCTAssertEqual(viewModel.amount, "10%")
        XCTAssertEqual(viewModel.description, "Coupon description")
        XCTAssertEqual(viewModel.expiryDate, "January 21, 2022")
    }

    func test_coupon_apply_rule_with_no_limit() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [], excludedProductIds: [], productCategories: [], excludedProductCategories: [])
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        XCTAssertEqual(viewModel.productsAppliedTo, NSLocalizedString("All Products", comment: ""))
    }

    func test_coupon_apply_rule_with_one_productId() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [12], excludedProductIds: [], productCategories: [], excludedProductCategories: [])
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        let appliedTo = String(format: NSLocalizedString("%d Product", comment: ""), 1)
        XCTAssertEqual(viewModel.productsAppliedTo, appliedTo)
    }

    func test_coupon_apply_rule_with_multiple_productIds() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [12, 23, 45], excludedProductIds: [], productCategories: [], excludedProductCategories: [])
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        let appliedTo = String(format: NSLocalizedString("%d Products", comment: ""), 3)
        XCTAssertEqual(viewModel.productsAppliedTo, appliedTo)
    }

    func test_coupon_apply_rule_with_multiple_productIds_and_categories() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [12, 23, 45], excludedProductIds: [], productCategories: [22, 33], excludedProductCategories: [])
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        let appliedTo = String(format: NSLocalizedString("%d Products and %d Categories", comment: ""), 3, 2)
        XCTAssertEqual(viewModel.productsAppliedTo, appliedTo)
    }

    func test_coupon_apply_rule_with_productIds_and_excluded_categories() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [12, 23, 45], excludedProductIds: [], productCategories: [], excludedProductCategories: [11])
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        let appliedTo = String(format: NSLocalizedString("%d Products except %d Category", comment: ""), 3, 1)
        XCTAssertEqual(viewModel.productsAppliedTo, appliedTo)
    }

    func test_coupon_apply_rule_with_categories_and_excluded_products() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [], excludedProductIds: [11, 22], productCategories: [1, 2, 3], excludedProductCategories: [])
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        let appliedTo = String(format: NSLocalizedString("%d Categories except %d Products", comment: ""), 3, 2)
        XCTAssertEqual(viewModel.productsAppliedTo, appliedTo)
    }

    func test_coupon_apply_rule_with_excluded_products() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [], excludedProductIds: [11, 22], productCategories: [], excludedProductCategories: [])
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        let appliedTo = String(format: NSLocalizedString("All except %d Products", comment: ""), 2)
        XCTAssertEqual(viewModel.productsAppliedTo, appliedTo)
    }

    func test_coupon_apply_rule_with_excluded_categories() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [], excludedProductIds: [], productCategories: [], excludedProductCategories: [11, 22])
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        let appliedTo = String(format: NSLocalizedString("All except %d Categories", comment: ""), 2)
        XCTAssertEqual(viewModel.productsAppliedTo, appliedTo)
    }

    func test_coupon_is_updated_after_synchronizing() {
        // Given
        let sampleCoupon = Coupon.fake().copy(amount: "15.00", discountType: .percent)
        let updatedCoupon = sampleCoupon.copy(amount: "10.00")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores)
        XCTAssertEqual(viewModel.amount, "15%")

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .retrieveCoupon(_, _, onCompletion):
                onCompletion(.success(updatedCoupon))
            default:
                break
            }
        }
        viewModel.syncCoupon()

        // Then
        XCTAssertEqual(viewModel.amount, "10%")
    }

    func test_coupon_performance_is_correct() {
        // Given
        let sampleCoupon = Coupon.fake()
        let sampleReport = CouponReport.fake().copy(amount: 220.0, ordersCount: 10)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores, currencySettings: CurrencySettings())
        XCTAssertEqual(viewModel.discountedOrdersCount, "0")
        XCTAssertEqual(viewModel.discountedAmount, "$0.00")

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .loadCouponReport(_, _, onCompletion):
                onCompletion(.success(sampleReport))
            default:
                break
            }
        }
        viewModel.loadCouponReport()

        // Then
        XCTAssertEqual(viewModel.discountedOrdersCount, "10")
        XCTAssertEqual(viewModel.discountedAmount, "$220.00")
    }
}
