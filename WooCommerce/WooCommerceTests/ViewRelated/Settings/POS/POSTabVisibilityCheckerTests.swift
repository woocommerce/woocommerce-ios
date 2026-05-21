import Foundation
import Testing
import Experiments
import Yosemite
@testable import WooCommerce

@MainActor
struct POSTabVisibilityCheckerTests {
    private var eligibilityService: MockPOSEligibilityService!
    private let site = Site.fake().copy(siteID: 2)
    private var siteID: Int64 { site.siteID }

    init() async throws {
        eligibilityService = MockPOSEligibilityService()
    }

    // MARK: - `checkVisibility`

    @Test func is_visible_on_iPad() async throws {
        // Given
        let checker = makeChecker(idiom: .pad, featureFlagService: MockFeatureFlagService())

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func is_visible_on_phone_when_phonePrototype_flag_enabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSalePhonePrototype] = true
        let checker = makeChecker(idiom: .phone, featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func is_invisible_on_phone_when_phonePrototype_flag_disabled() async throws {
        // Given
        let checker = makeChecker(idiom: .phone, featureFlagService: MockFeatureFlagService())

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    // MARK: - `checkInitialVisibility`

    @Test func checkInitialVisibility_returns_true_when_cached_tab_visibility_is_enabled() async throws {
        // Given
        let checker = makeChecker()
        setupPOSTabVisibility(siteID: siteID, isVisible: true)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_disabled() async throws {
        // Given
        let checker = makeChecker()
        setupPOSTabVisibility(siteID: siteID, isVisible: false)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_unavailable() async throws {
        // Given
        let checker = makeChecker()
        setupPOSTabVisibility(siteID: siteID, isVisible: nil)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }
}

private extension POSTabVisibilityCheckerTests {
    func makeChecker(idiom: UIUserInterfaceIdiom = .pad,
                     featureFlagService: MockFeatureFlagService = MockFeatureFlagService()) -> POSTabVisibilityChecker {
        POSTabVisibilityChecker(site: site,
                                userInterfaceIdiom: idiom,
                                eligibilityService: eligibilityService,
                                featureFlagService: featureFlagService)
    }

    func setupPOSTabVisibility(siteID: Int64, isVisible: Bool?) {
        eligibilityService.cachedTabVisibility[siteID] = isVisible
    }
}
