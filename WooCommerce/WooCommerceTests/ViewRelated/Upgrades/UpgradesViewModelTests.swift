import XCTest
@testable import WooCommerce

final class UpgradesViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345

    func test_initial_UpgradesViewModel_initializes_with_correct_empty_values() {

        let expectation = XCTestExpectation(description: "Waiting for main queue")

        Task {
            // Given
            let sut = await UpgradesViewModel(siteID: sampleSiteID)

            let initialWpcomPlans = await sut.wpcomPlans
            let initialEntitledWpcomPlanIDs = await sut.entitledWpcomPlanIDs

            // When/Then
            DispatchQueue.main.async {
                XCTAssertTrue(initialWpcomPlans.isEmpty)
                XCTAssertTrue(initialEntitledWpcomPlanIDs.isEmpty)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_inAppPurchasesPlanManager() {
        /**
         TODO: https://github.com/woocommerce/woocommerce-ios/issues/9884
         In order to pass a `MockInAppPurchases` and test the view model behavior,
         we need to inject it into the initializer via `InAppPurchasesForWPComPlansProtocol`.
         This cannot be done at the moment due to the concrete `InAppPurchasesForWPComPlansManager` concrete implementation using `@MainActor` on class-level.
         */
    }
}
