import StoreKit
import TestKit
import XCTest
import Yosemite
@testable import WooCommerce

final class WebPurchasesForWPComPlansTests: XCTestCase {
    private var stores: MockStoresManager!
    private var webPurchases: WebPurchasesForWPComPlans!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        webPurchases = WebPurchasesForWPComPlans(stores: stores)
    }

    override func tearDown() {
        webPurchases = nil
        stores = nil
        super.tearDown()
    }

    // MARK: - `fetchProducts`

    func test_fetchProducts_returns_plan_from_PaymentAction_loadPlan() async throws {
        // Given
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            if case let .loadPlan(_, completion) = action {
                completion(.success(.init(productID: 645, name: "woo plan", formattedPrice: "$ 32.8")))
            }
        }

        // When
        let products = try await webPurchases.fetchProducts()

        // Then
        XCTAssertEqual(products as? [WebPurchasesForWPComPlans.Plan],
                       [.init(displayName: "woo plan", description: "", id: "645", displayPrice: "$ 32.8")])
    }

    func test_fetchProducts_returns_error_from_PaymentAction_loadPlan() async throws {
        // Given
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            if case let .loadPlan(_, completion) = action {
                completion(.failure(SampleError.first))
            }
        }

        await assertThrowsError({
            // When
            _ = try await webPurchases.fetchProducts()
        }) { error in
            // Then
            (error as? SampleError) == .first
        }
    }

    // MARK: - `purchaseProduct`

    func test_purchaseProduct_returns_pending_result_from_PaymentAction_createCart_success() async throws {
        // Given
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            if case let .createCart(_, _, completion) = action {
                completion(.success(()))
            }
        }

        // When
        let purchaseResult = try await webPurchases.purchaseProduct(with: "productID", for: 134)

        // Then
        XCTAssertEqual(purchaseResult, .pending)
    }

    func test_purchaseProduct_returns_error_from_PaymentAction_createCart_failure() async throws {
        // Given
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            if case let .createCart(_, _, completion) = action {
                completion(.failure(SampleError.first))
            }
        }

        await assertThrowsError({
            // When
            _ = try await webPurchases.purchaseProduct(with: "productID", for: 134)
        }) { error in
            // Then
            (error as? SampleError) == .first
        }
    }

    // MARK: - `userIsEntitledToProduct`

    func test_userIsEntitledToProduct_returns_false() async throws {
        // When
        let userIsEntitledToProduct = try await webPurchases.userIsEntitledToProduct(with: "1021")

        // Then
        XCTAssertFalse(userIsEntitledToProduct)
    }

    // MARK: - `inAppPurchasesAreSupported`

    func test_inAppPurchasesAreSupported_returns_true() async throws {
        // When
        let inAppPurchasesAreSupported = await webPurchases.inAppPurchasesAreSupported()

        // Then
        XCTAssertTrue(inAppPurchasesAreSupported)
    }
}

extension StoreKit.Product.PurchaseResult: Equatable {
    public static func == (lhs: StoreKit.Product.PurchaseResult, rhs: StoreKit.Product.PurchaseResult) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending):
            return true
        case (.userCancelled, .userCancelled):
            return true
        default:
            return false
        }
    }
}
