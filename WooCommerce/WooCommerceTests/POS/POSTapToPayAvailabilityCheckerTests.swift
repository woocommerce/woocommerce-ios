import Testing
import Foundation
import Yosemite
import enum WooFoundation.CountryCode
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSTapToPayAvailabilityCheckerTests {

    private let siteID: Int64 = 123

    // MARK: - Hardware Support Gate

    @Test func checkAvailability_when_tapToPay_hardware_unsupported_then_returns_deviceNotSupported() async {
        // Given
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachedTabVisibility[siteID] = true
        let sut = makeSUT(eligibilityService: eligibilityService,
                          isTapToPayHardwareSupported: false)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .unavailable(reason: .deviceNotSupported))
    }

    @Test func checkAvailability_when_tapToPay_hardware_unsupported_then_does_not_dispatch_device_check() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var deviceCheckDispatched = false
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport = action {
                deviceCheckDispatched = true
            }
        }
        let sut = makeSUT(stores: stores, isTapToPayHardwareSupported: false)

        // When
        _ = await sut.checkAvailability()

        // Then
        #expect(deviceCheckDispatched == false)
    }

    // MARK: - Device Support Gate

    @Test func checkAvailability_when_device_not_supported_then_returns_deviceNotSupported() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport(_, _, _, _, let completion) = action {
                completion(false)
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachedTabVisibility[123] = true
        let sut = makeSUT(stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .unavailable(reason: .deviceNotSupported))
    }

    @Test(arguments: [CountryCode.PR, .CA, .AU])
    func checkAvailability_when_store_country_does_not_support_tapToPay_then_does_not_dispatch_device_check(countryCode: CountryCode) async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var deviceCheckDispatched = false
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport = action {
                deviceCheckDispatched = true
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachedTabVisibility[siteID] = true
        let sut = makeSUT(countryCode: countryCode, stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .unavailable(reason: .siteNotEligible))
        #expect(deviceCheckDispatched == false)
    }

    // MARK: - Site Eligibility Gate

    @Test func checkAvailability_when_device_supported_but_site_not_eligible_then_returns_siteNotEligible() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport(_, _, _, _, let completion) = action {
                completion(true)
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachedTabVisibility[siteID] = false
        let sut = makeSUT(stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .unavailable(reason: .siteNotEligible))
    }

    @Test func checkAvailability_when_site_eligibility_nil_cached_then_returns_siteNotEligible() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport(_, _, _, _, let completion) = action {
                completion(true)
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        // cachedTabVisibility has no entry for siteID → returns nil → treated as ineligible
        let sut = makeSUT(stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .unavailable(reason: .siteNotEligible))
    }

    // MARK: - All Gates Pass

    @Test func checkAvailability_when_all_gates_pass_then_returns_available() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport(_, _, _, _, let completion) = action {
                completion(true)
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachedTabVisibility[siteID] = true
        let sut = makeSUT(stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .available)
    }

    @Test(arguments: [CountryCode.PR, .CA, .AU])
    func checkAvailability_when_store_country_does_not_support_tapToPay_then_returns_siteNotEligible(countryCode: CountryCode) async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport(_, _, _, _, let completion) = action {
                completion(true)
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachedTabVisibility[siteID] = true
        let sut = makeSUT(countryCode: countryCode, stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .unavailable(reason: .siteNotEligible))
    }

    @Test func checkAvailability_when_store_is_in_GB_and_all_gates_pass_then_returns_available() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .checkDeviceSupport(_, _, _, _, let completion) = action {
                completion(true)
            }
        }
        let eligibilityService = MockPOSEligibilityService()
        eligibilityService.cachedTabVisibility[siteID] = true
        let sut = makeSUT(countryCode: .GB, stores: stores, eligibilityService: eligibilityService)

        // When
        let result = await sut.checkAvailability()

        // Then
        #expect(result == .available)
    }
}

// MARK: - Helpers

private extension POSTapToPayAvailabilityCheckerTests {
    /// Hardware support defaults to `true` so the device / eligibility tests stay deterministic
    /// regardless of the simulator the suite runs on.
    func makeSUT(
        countryCode: CountryCode = .US,
        stores: MockStoresManager = MockStoresManager(sessionManager: .makeForTesting()),
        eligibilityService: MockPOSEligibilityService = MockPOSEligibilityService(),
        isTapToPayHardwareSupported: Bool = true
    ) -> POSTapToPayAvailabilityChecker {
        POSTapToPayAvailabilityChecker(
            siteID: siteID,
            countryCode: countryCode,
            stores: stores,
            eligibilityService: eligibilityService,
            isTapToPayHardwareSupported: isTapToPayHardwareSupported
        )
    }
}
