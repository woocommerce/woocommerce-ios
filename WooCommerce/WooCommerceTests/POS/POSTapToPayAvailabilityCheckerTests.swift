import Testing
import Foundation
import Experiments
import Yosemite
@testable import WooCommerce

@Suite(.timeLimit(.minutes(5)))
struct POSTapToPayAvailabilityCheckerTests {

    private let siteID: Int64 = 123

    // MARK: - Feature Flag Gate

    @Test func checkAvailability_when_featureFlag_disabled_then_returns_featureFlagDisabled() async {
        // Given
        let featureFlags = MockFeatureFlagService()
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleTapToPay] = false
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = makeSUT(featureFlagService: featureFlags, stores: stores)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .unavailable(reason: .featureFlagDisabled))
    }

    @Test func checkAvailability_when_featureFlag_disabled_then_does_not_dispatch_device_check() async {
        // Given
        let featureFlags = MockFeatureFlagService()
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleTapToPay] = false
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var deviceCheckDispatched = false
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport = action {
                deviceCheckDispatched = true
            }
        }
        let sut = makeSUT(featureFlagService: featureFlags, stores: stores)

        // When
        _ = await sut.checkAvailability()

        // Then
        #expect(deviceCheckDispatched == false)
    }

    // MARK: - Device Support Gate

    @Test func checkAvailability_when_featureFlag_on_but_device_not_supported_then_returns_deviceNotSupported() async {
        // Given
        let featureFlags = makeEnabledFeatureFlags()
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport(_, _, _, _, let completion) = action {
                completion(false)
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachedTabVisibility[123] = true
        let sut = makeSUT(featureFlagService: featureFlags, stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .unavailable(reason: .deviceNotSupported))
    }

    @Test func checkAvailability_when_device_not_supported_then_does_not_check_site_eligibility() async {
        // Given
        let featureFlags = makeEnabledFeatureFlags()
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport(_, _, _, _, let completion) = action {
                completion(false)
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        // No cached visibility set — if eligibility were checked, loadCachedPOSTabVisibility returns nil → false
        let sut = makeSUT(featureFlagService: featureFlags, stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then — result is deviceNotSupported (not siteNotEligible), confirming eligibility was not the gate
        #expect(result == .unavailable(reason: .deviceNotSupported))
    }

    // MARK: - Site Eligibility Gate

    @Test func checkAvailability_when_featureFlag_on_device_supported_but_site_not_eligible_then_returns_siteNotEligible() async {
        // Given
        let featureFlags = makeEnabledFeatureFlags()
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport(_, _, _, _, let completion) = action {
                completion(true)
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachedTabVisibility[siteID] = false
        let sut = makeSUT(featureFlagService: featureFlags, stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .unavailable(reason: .siteNotEligible))
    }

    @Test func checkAvailability_when_site_eligibility_nil_cached_then_returns_siteNotEligible() async {
        // Given
        let featureFlags = makeEnabledFeatureFlags()
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport(_, _, _, _, let completion) = action {
                completion(true)
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        // cachedTabVisibility has no entry for siteID → returns nil → treated as ineligible
        let sut = makeSUT(featureFlagService: featureFlags, stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .unavailable(reason: .siteNotEligible))
    }

    // MARK: - All Gates Pass

    @Test func checkAvailability_when_all_gates_pass_then_returns_available() async {
        // Given
        let featureFlags = makeEnabledFeatureFlags()
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport(_, _, _, _, let completion) = action {
                completion(true)
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachedTabVisibility[siteID] = true
        let sut = makeSUT(featureFlagService: featureFlags, stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .available)
    }
}

// MARK: - Helpers

private extension POSTapToPayAvailabilityCheckerTests {
    func makeEnabledFeatureFlags() -> MockFeatureFlagService {
        let service = MockFeatureFlagService()
        service.isFeatureFlagEnabledReturnValue[.pointOfSaleTapToPay] = true
        return service
    }

    func makeSUT(
        featureFlagService: MockFeatureFlagService = MockFeatureFlagService(),
        stores: MockStoresManager = MockStoresManager(sessionManager: .makeForTesting()),
        eligibilityService: MockPOSEligibilityService = MockPOSEligibilityService()
    ) -> POSTapToPayAvailabilityChecker {
        POSTapToPayAvailabilityChecker(
            siteID: siteID,
            stores: stores,
            featureFlagService: featureFlagService,
            eligibilityService: eligibilityService
        )
    }
}
