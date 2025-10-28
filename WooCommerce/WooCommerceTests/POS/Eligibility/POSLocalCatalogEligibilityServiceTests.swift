import Foundation
import Testing
import PointOfSale
@testable import WooCommerce
@testable import Yosemite
import protocol Experiments.FeatureFlagService
import enum Experiments.FeatureFlag

@Suite("POSLocalCatalogEligibilityService Tests")
@MainActor
struct POSLocalCatalogEligibilityServiceTests {
    private let siteID: Int64 = 123

    // MARK: - Catalog Size Within Limit

    @Test("Catalog size within limit returns eligible")
    func testCatalogSizeWithinLimitReturnsEligible() async {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let featureFlagService = MockFeatureFlagService(isLocalCatalogEnabled: true)
        let service = POSLocalCatalogEligibilityService(
            siteID: siteID,
            catalogSizeChecker: sizeChecker,
            isLocalCatalogFeatureFlagEnabled: featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1),
            isPOSTabVisible: true,
            catalogSizeLimit: 1000
        )

        #expect(await service.eligibilityState == .eligible)
    }

    @Test("Exactly at size limit returns eligible")
    func testExactlyAtSizeLimitReturnsEligible() async {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 600, variationCount: 400))
        )
        let featureFlagService = MockFeatureFlagService(isLocalCatalogEnabled: true)
        let service = POSLocalCatalogEligibilityService(
            siteID: siteID,
            catalogSizeChecker: sizeChecker,
            isLocalCatalogFeatureFlagEnabled: featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1),
            isPOSTabVisible: true,
            catalogSizeLimit: 1000
        )

        #expect(await service.eligibilityState == .eligible)
    }

    // MARK: - Catalog Size Exceeds Limit

    @Test("Catalog one over limit returns ineligible")
    func testCatalogOneOverLimitReturnsIneligible() async {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 501, variationCount: 500))
        )
        let featureFlagService = MockFeatureFlagService(isLocalCatalogEnabled: true)
        let service = POSLocalCatalogEligibilityService(
            siteID: siteID,
            catalogSizeChecker: sizeChecker,
            isLocalCatalogFeatureFlagEnabled: featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1),
            isPOSTabVisible: true,
            catalogSizeLimit: 1000
        )

        let state = await service.eligibilityState

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .catalogSizeTooLarge(let totalCount, let limit) = reason else {
            Issue.record("Expected catalogSizeTooLarge reason")
            return
        }

        #expect(totalCount == 1001)
        #expect(limit == 1000)
    }

    // MARK: - Catalog Size Check Failure

    @Test("Catalog size check failure returns ineligible")
    func testCatalogSizeCheckFailureReturnsIneligible() async {
        let expectedError = NSError(domain: "test", code: 123, userInfo: nil)
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .failure(expectedError)
        )
        let featureFlagService = MockFeatureFlagService(isLocalCatalogEnabled: true)
        let service = POSLocalCatalogEligibilityService(
            siteID: siteID,
            catalogSizeChecker: sizeChecker,
            isLocalCatalogFeatureFlagEnabled: featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1),
            isPOSTabVisible: true,
            catalogSizeLimit: 1000
        )

        let state = await service.eligibilityState

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .catalogSizeCheckFailed(let errorString) = reason else {
            Issue.record("Expected catalogSizeCheckFailed reason")
            return
        }

        #expect(errorString.contains("123"))
    }

    // MARK: - Caching

    @Test("Second call uses cached state")
    func testSecondCallUsesCachedState() async {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let featureFlagService = MockFeatureFlagService(isLocalCatalogEnabled: true)
        let service = POSLocalCatalogEligibilityService(
            siteID: siteID,
            catalogSizeChecker: sizeChecker,
            isLocalCatalogFeatureFlagEnabled: featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1),
            isPOSTabVisible: true,
            catalogSizeLimit: 1000
        )

        // First call
        let firstState = await service.eligibilityState
        #expect(firstState == .eligible)
        #expect(sizeChecker.checkCatalogSizeCallCount == 1)

        // Second call should use cache
        let secondState = await service.eligibilityState
        #expect(secondState == .eligible)
        #expect(sizeChecker.checkCatalogSizeCallCount == 1) // Should not increment
    }

    @Test("Refresh bypasses cache")
    func testRefreshBypassesCache() async {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let featureFlagService = MockFeatureFlagService(isLocalCatalogEnabled: true)
        let service = POSLocalCatalogEligibilityService(
            siteID: siteID,
            catalogSizeChecker: sizeChecker,
            isLocalCatalogFeatureFlagEnabled: featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1),
            isPOSTabVisible: true,
            catalogSizeLimit: 1000
        )

        // First call
        let firstState = await service.eligibilityState
        #expect(firstState == .eligible)
        #expect(sizeChecker.checkCatalogSizeCallCount == 1)

        // Refresh should fetch again
        let refreshedState = await service.refreshEligibilityState()
        #expect(refreshedState == .eligible)
        #expect(sizeChecker.checkCatalogSizeCallCount == 2) // Should increment
    }

    @Test("Refresh updates cache")
    func testRefreshUpdatesCache() async {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let featureFlagService = MockFeatureFlagService(isLocalCatalogEnabled: true)
        let service = POSLocalCatalogEligibilityService(
            siteID: siteID,
            catalogSizeChecker: sizeChecker,
            isLocalCatalogFeatureFlagEnabled: featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1),
            isPOSTabVisible: true,
            catalogSizeLimit: 1000
        )

        // First call caches eligible state
        _ = await service.eligibilityState
        #expect(sizeChecker.checkCatalogSizeCallCount == 1)

        // Change the size checker to return ineligible
        sizeChecker.sizeToReturn = .success(POSCatalogSize(productCount: 1000, variationCount: 100))

        // Refresh should update cache
        let refreshedState = await service.refreshEligibilityState()
        guard case .ineligible = refreshedState else {
            Issue.record("Expected ineligible after refresh")
            return
        }
        #expect(sizeChecker.checkCatalogSizeCallCount == 2)

        // Next get should return cached ineligible
        let cachedState = await service.eligibilityState
        guard case .ineligible = cachedState else {
            Issue.record("Expected cached ineligible state")
            return
        }
        #expect(sizeChecker.checkCatalogSizeCallCount == 2) // Should not increment
    }

    // MARK: - Feature Flag

    @Test("Feature flag disabled returns ineligible")
    func testFeatureFlagDisabledReturnsIneligible() async {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let featureFlagService = MockFeatureFlagService(isLocalCatalogEnabled: false)
        let service = POSLocalCatalogEligibilityService(
            siteID: siteID,
            catalogSizeChecker: sizeChecker,
            isLocalCatalogFeatureFlagEnabled: featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1),
            isPOSTabVisible: true,
            catalogSizeLimit: 1000
        )

        let state = await service.eligibilityState

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .featureFlagDisabled = reason else {
            Issue.record("Expected featureFlagDisabled reason")
            return
        }

        // Should not have checked catalog size
        #expect(sizeChecker.checkCatalogSizeCallCount == 0)
    }

    // MARK: - Custom Size Limit

    @Test("Custom size limit is respected")
    func testCustomSizeLimitIsRespected() async {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 100, variationCount: 50))
        )
        let featureFlagService = MockFeatureFlagService(isLocalCatalogEnabled: true)
        let service = POSLocalCatalogEligibilityService(
            siteID: siteID,
            catalogSizeChecker: sizeChecker,
            isLocalCatalogFeatureFlagEnabled: featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1),
            isPOSTabVisible: true,
            catalogSizeLimit: 100 // Custom lower limit
        )

        let state = await service.eligibilityState

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .catalogSizeTooLarge(let totalCount, let limit) = reason else {
            Issue.record("Expected catalogSizeTooLarge reason")
            return
        }

        #expect(totalCount == 150)
        #expect(limit == 100)
    }

    // MARK: - POS Tab Visibility

    @Test("POS tab not visible returns ineligible")
    func testPOSTabNotVisibleReturnsIneligible() async {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let featureFlagService = MockFeatureFlagService(isLocalCatalogEnabled: true)
        let service = POSLocalCatalogEligibilityService(
            siteID: siteID,
            catalogSizeChecker: sizeChecker,
            isLocalCatalogFeatureFlagEnabled: featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1),
            isPOSTabVisible: false,
            catalogSizeLimit: 1000
        )

        let state = await service.eligibilityState

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .posTabNotVisible = reason else {
            Issue.record("Expected posTabNotVisible reason")
            return
        }

        // Should not have checked catalog size
        #expect(sizeChecker.checkCatalogSizeCallCount == 0)
    }

    @Test("POS tab visibility checked before catalog size")
    func testPOSTabVisibilityCheckedFirst() async {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 2000, variationCount: 0))
        )
        let featureFlagService = MockFeatureFlagService(isLocalCatalogEnabled: true)
        let service = POSLocalCatalogEligibilityService(
            siteID: siteID,
            catalogSizeChecker: sizeChecker,
            isLocalCatalogFeatureFlagEnabled: featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1),
            isPOSTabVisible: false,
            catalogSizeLimit: 1000
        )

        // Should be ineligible due to POS tab not visible, not catalog size
        guard case .ineligible(let reason) = await service.eligibilityState else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .posTabNotVisible = reason else {
            Issue.record("Expected posTabNotVisible reason, not catalogSizeTooLarge")
            return
        }

        // Should not have checked catalog size since POS tab wasn't visible
        #expect(sizeChecker.checkCatalogSizeCallCount == 0)
    }
}
