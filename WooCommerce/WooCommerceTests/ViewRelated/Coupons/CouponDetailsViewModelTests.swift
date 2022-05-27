import XCTest

import WooFoundation
@testable import Yosemite
@testable import WooCommerce

final class CouponDetailsViewModelTests: XCTestCase {

    func test_amount_is_correct_for_fixedProduct_discount_type() {
        // Given
        let sampleCoupon = Coupon.fake().copy(
            amount: "10.00",
            discountType: .fixedProduct
        )
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.amount, "$10.00")
    }

    func test_amount_is_correct_for_percentage_discount_type() {
        // Given
        let sampleCoupon = Coupon.fake().copy(
            amount: "10.00",
            discountType: .percent
        )
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        XCTAssertEqual(viewModel.amount, "10%")
    }

    func test_coupon_details_are_correct() {
        let sampleCoupon = Coupon.fake().copy(
            code: "AGK32FD",
            amount: "10.00",
            discountType: .percent,
            description: "Coupon description",
            dateExpires: Date(timeIntervalSince1970: 1642755825), // GMT: January 21, 2022
            individualUse: true,
            productIds: [],
            usageLimit: 1200,
            usageLimitPerUser: 3,
            limitUsageToXItems: 10,
            freeShipping: true,
            excludeSaleItems: false,
            minimumAmount: "5.00",
            emailRestrictions: ["*@a8c.com", "someone.else@example.com"]
        )
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, currencySettings: .init())

        // Then
        XCTAssertEqual(viewModel.couponCode, "AGK32FD")
        XCTAssertEqual(viewModel.amount, "10%")
        XCTAssertEqual(viewModel.description, "Coupon description")
        XCTAssertEqual(viewModel.expiryDate, "January 21, 2022")
        XCTAssertEqual(viewModel.discountType, NSLocalizedString("Percentage Discount", comment: ""))
        XCTAssertFalse(viewModel.excludeSaleItems)
        XCTAssertTrue(viewModel.allowsFreeShipping)
        XCTAssertEqual(viewModel.usageLimit, 1200)
        XCTAssertEqual(viewModel.usageLimitPerUser, 3)
        XCTAssertEqual(viewModel.limitUsageToXItems, 10)
        XCTAssertEqual(viewModel.minimumAmount, "$5.00")
        XCTAssertEqual(viewModel.maximumAmount, "")
        XCTAssertEqual(viewModel.emailRestrictions, ["*@a8c.com", "someone.else@example.com"])
        XCTAssertTrue(viewModel.individualUseOnly)
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

    func test_coupon_performance_is_correct_with_usage_count_equal_to_0() {
        // Given
        let sampleCoupon = Coupon.fake().copy(usageCount: 0)
        let sampleReport = CouponReport.fake().copy(amount: 0, ordersCount: 0)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores, currencySettings: CurrencySettings())
        XCTAssertEqual(viewModel.discountedOrdersCount, "0")
        XCTAssertEqual(viewModel.discountedAmount, "$0.00")

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .loadCouponReport(_, _, _, onCompletion):
                onCompletion(.success(sampleReport))
            default:
                break
            }
        }
        viewModel.loadCouponReport()

        // Then
        XCTAssertEqual(viewModel.discountedOrdersCount, "0")
        XCTAssertEqual(viewModel.discountedAmount, "$0.00")
    }

    func test_coupon_performance_is_correct_with_usage_count_larger_than_0() {
        // Given
        let sampleCoupon = Coupon.fake().copy(usageCount: 10)
        let sampleReport = CouponReport.fake().copy(amount: 220.0, ordersCount: 10)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores, currencySettings: CurrencySettings())
        XCTAssertEqual(viewModel.discountedOrdersCount, "10")
        XCTAssertEqual(viewModel.discountedAmount, nil)

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .loadCouponReport(_, _, _, onCompletion):
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

    func test_coupon_share_message_is_correct_if_there_is_no_restriction() {
        // Given
        let sampleCoupon = Coupon.fake().copy(code: "TEST", amount: "10.00", discountType: .percent)
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        let shareMessage = String(format: NSLocalizedString("Apply %@ off to all products with the promo code “%@”.", comment: ""), "10%", "TEST")
        XCTAssertEqual(viewModel.shareMessage, shareMessage)
    }

    func test_coupon_share_message_is_correct_if_there_is_product_restriction() {
        // Given
        let sampleCoupon = Coupon.fake().copy(code: "TEST", amount: "10.00", discountType: .percent, productIds: [12, 23])
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        let shareMessage = String(format: NSLocalizedString("Apply %@ off to some products with the promo code “%@”.", comment: ""), "10%", "TEST")
        XCTAssertEqual(viewModel.shareMessage, shareMessage)
    }

    func test_hasErrorLoadingAmount_and_hasWCAnalyticsDisabled_return_false_initially() {
        // Given
        let sampleCoupon = Coupon.fake().copy(code: "TEST", amount: "10.00", discountType: .percent, productIds: [12, 23])
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        XCTAssertFalse(viewModel.hasErrorLoadingAmount)
        XCTAssertFalse(viewModel.hasWCAnalyticsDisabled)
    }

    func test_hasErrorLoadingAmount_returns_false_if_loading_amount_succeeds() {
        // Given
        let sampleCoupon = Coupon.fake().copy(code: "TEST", amount: "10.00", discountType: .percent, productIds: [12, 23])
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores)

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case .loadCouponReport(_, _, _, let onCompletion):
                onCompletion(.success(CouponReport(couponID: 234, amount: 20, ordersCount: 1)))
            default:
                break
            }
        }
        viewModel.loadCouponReport()

        // Then
        XCTAssertFalse(viewModel.hasErrorLoadingAmount)
    }

    func test_hasErrorLoadingAmount_returns_true_if_loading_amount_fails_and_retrieveAnalyticsSetting_returns_true() {
        // Given
        let sampleCoupon = Coupon.fake().copy(code: "TEST", amount: "10.00", discountType: .percent, productIds: [12, 23])
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores)

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case .loadCouponReport(_, _, _, let onCompletion):
                let error = NSError(domain: "Test", code: 0, userInfo: [:])
                onCompletion(.failure(error))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsSetting(_, onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        viewModel.loadCouponReport()

        // Then
        XCTAssertTrue(viewModel.hasErrorLoadingAmount)
        XCTAssertFalse(viewModel.hasWCAnalyticsDisabled)
    }

    func test_hasErrorLoadingAmount_returns_true_if_loading_amount_fails_and_retrieveAnalyticsSetting_returns_false() {
        // Given
        let sampleCoupon = Coupon.fake().copy(code: "TEST", amount: "10.00", discountType: .percent, productIds: [12, 23])
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores)

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case .loadCouponReport(_, _, _, let onCompletion):
                let error = NSError(domain: "Test", code: 0, userInfo: [:])
                onCompletion(.failure(error))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsSetting(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.loadCouponReport()

        // Then
        XCTAssertFalse(viewModel.hasErrorLoadingAmount)
        XCTAssertTrue(viewModel.hasWCAnalyticsDisabled)
    }

    func test_shouldShowErrorLoadingAmount_returns_false_if_usageCount_is_zero() {
        // Given
        let sampleCoupon = Coupon.fake().copy(code: "TEST", amount: "10.00", discountType: .percent, usageCount: 0, productIds: [12, 23])
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores)

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case .loadCouponReport(_, _, _, let onCompletion):
                let error = NSError(domain: "Test", code: 0, userInfo: [:])
                onCompletion(.failure(error))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsSetting(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.loadCouponReport()

        // Then
        XCTAssertTrue(viewModel.hasWCAnalyticsDisabled) // Confidence check
        XCTAssertFalse(viewModel.shouldShowErrorLoadingAmount)
    }

    func test_shouldShowErrorLoadingAmount_returns_true_if_usageCount_is_not_zero() {
        // Given
        let sampleCoupon = Coupon.fake().copy(code: "TEST", amount: "10.00", discountType: .percent, usageCount: 1, productIds: [12, 23])
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores)

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case .loadCouponReport(_, _, _, let onCompletion):
                let error = NSError(domain: "Test", code: 0, userInfo: [:])
                onCompletion(.failure(error))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsSetting(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.loadCouponReport()

        // Then
        XCTAssertTrue(viewModel.hasWCAnalyticsDisabled) // Confidence check
        XCTAssertTrue(viewModel.shouldShowErrorLoadingAmount)
    }

    func test_deleteCoupon_triggers_onSuccess_if_deletion_succeeds() {
        // Given
        let sampleCoupon = Coupon.fake().copy(siteID: 123, couponID: 456)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores)
        var onSuccessTriggered = false
        var onFailureTriggered = false
        let onSuccess: () -> Void = {
            onSuccessTriggered = true
        }
        let onFailure: () -> Void = {
            onFailureTriggered = true
        }

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .deleteCoupon(siteID, couponID, onCompletion):
                // Confidence check
                XCTAssertEqual(siteID, sampleCoupon.siteID)
                XCTAssertEqual(couponID, sampleCoupon.couponID)
                onCompletion(.success(()))
            default:
                break
            }
        }
        viewModel.deleteCoupon(onSuccess: onSuccess, onFailure: onFailure)

        // Then
        XCTAssertTrue(onSuccessTriggered)
        XCTAssertFalse(onFailureTriggered)
    }

    func test_deleteCoupon_triggers_onFailure_if_deletion_fails() {
        // Given
        let sampleCoupon = Coupon.fake().copy(siteID: 123, couponID: 456)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores)
        var onSuccessTriggered = false
        var onFailureTriggered = false
        let onSuccess: () -> Void = {
            onSuccessTriggered = true
        }
        let onFailure: () -> Void = {
            onFailureTriggered = true
        }

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .deleteCoupon(_, _, onCompletion):
                let error = NSError(domain: "test", code: 400, userInfo: nil)
                onCompletion(.failure(error))
            default:
                break
            }
        }
        viewModel.deleteCoupon(onSuccess: onSuccess, onFailure: onFailure)

        // Then
        XCTAssertFalse(onSuccessTriggered)
        XCTAssertTrue(onFailureTriggered)
    }

    func test_deleteCoupon_updates_isLoading_correctly() {
        // Given
        let sampleCoupon = Coupon.fake().copy(siteID: 123, couponID: 456)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, stores: stores)
        XCTAssertFalse(viewModel.isDeletionInProgress)

        // When
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .deleteCoupon(_, _, onCompletion):
                XCTAssertTrue(viewModel.isDeletionInProgress)
                onCompletion(.success(()))
            default:
                break
            }
        }
        viewModel.deleteCoupon(onSuccess: {}, onFailure: {})

        // Then
        XCTAssertFalse(viewModel.isDeletionInProgress)
    }
}
