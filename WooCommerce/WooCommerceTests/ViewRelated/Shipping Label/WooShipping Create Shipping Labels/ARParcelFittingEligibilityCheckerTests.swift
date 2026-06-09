import Experiments
import Testing
import Yosemite
import enum AutomatticTracks.Variation
@testable import WooCommerce

@MainActor
struct ARParcelFittingEligibilityCheckerTests {

    // localFF AND (remoteFF OR explatTreatment)
    // (remoteFF, explatTreatment, localFF, expected)
    @Test
    func test_isEligible_for_all_flag_permutations() async {
        let cases: [(Bool, Bool, Bool, Bool)] = [
            (false, false, false, false),
            (false, false, true, false),
            (false, true, false, false),
            (false, true, true, true),
            (true, false, false, false),
            (true, false, true, true),
            (true, true, false, false),
            (true, true, true, true),
        ]

        for (remoteFF, explatTreatment, localFF, expected) in cases {
            // Given
            let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
            stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
                switch action {
                case let .isRemoteFeatureFlagEnabled(_, _, _, completion):
                    completion(remoteFF)
                }
            }
            let featureFlagService = MockFeatureFlagService()
            featureFlagService.isFeatureFlagEnabledReturnValue[.arParcelFitting] = localFF
            let abTestProvider = MockABTestVariationProvider()
            abTestProvider.mockVariationValue = explatTreatment ? .treatment : .control

            let sut = ARParcelFittingEligibilityChecker(featureFlagService: featureFlagService,
                                                        abTestVariationProvider: abTestProvider,
                                                        stores: stores,
                                                        isARWorldTrackingSupported: true)

            // When
            let result = await sut.isEligible()

            // Then
            #expect(result == expected,
                    "remoteFF=\(remoteFF), explat=\(explatTreatment), localFF=\(localFF)")
        }
    }

    @Test
    func test_isEligible_when_AR_not_supported_then_returns_false() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, _, completion):
                completion(true)
            }
        }
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.arParcelFitting] = true
        let abTestProvider = MockABTestVariationProvider()
        abTestProvider.mockVariationValue = .treatment

        let sut = ARParcelFittingEligibilityChecker(featureFlagService: featureFlagService,
                                                    abTestVariationProvider: abTestProvider,
                                                    stores: stores,
                                                    isARWorldTrackingSupported: false)

        // When
        let result = await sut.isEligible()

        // Then
        #expect(result == false)
    }

    @Test
    func test_isEligible_when_localFF_off_then_does_not_dispatch_remote_check() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.arParcelFitting] = false
        let abTestProvider = MockABTestVariationProvider()
        abTestProvider.mockVariationValue = .control

        let sut = ARParcelFittingEligibilityChecker(featureFlagService: featureFlagService,
                                                    abTestVariationProvider: abTestProvider,
                                                    stores: stores,
                                                    isARWorldTrackingSupported: true)

        // When
        let result = await sut.isEligible()

        // Then
        #expect(result == false)
        #expect(stores.receivedActions.isEmpty)
    }

    @Test
    func test_isEligible_when_explat_treatment_then_does_not_dispatch_remote_check() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.arParcelFitting] = true
        let abTestProvider = MockABTestVariationProvider()
        abTestProvider.mockVariationValue = .treatment

        let sut = ARParcelFittingEligibilityChecker(featureFlagService: featureFlagService,
                                                    abTestVariationProvider: abTestProvider,
                                                    stores: stores,
                                                    isARWorldTrackingSupported: true)

        // When
        let result = await sut.isEligible()

        // Then
        #expect(result == true)
        #expect(stores.receivedActions.isEmpty)
    }

    @Test
    func test_isEligible_dispatches_remote_check_with_defaultValue_false() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, _, completion):
                completion(false)
            }
        }
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.arParcelFitting] = true
        let abTestProvider = MockABTestVariationProvider()
        abTestProvider.mockVariationValue = .control

        let sut = ARParcelFittingEligibilityChecker(featureFlagService: featureFlagService,
                                                    abTestVariationProvider: abTestProvider,
                                                    stores: stores,
                                                    isARWorldTrackingSupported: true)

        // When
        _ = await sut.isEligible()

        // Then
        let dispatched = stores.receivedActions.compactMap { $0 as? FeatureFlagAction }
        #expect(dispatched.count == 1)
        if case let .isRemoteFeatureFlagEnabled(flag, defaultValue, _, _) = dispatched.first {
            #expect(flag == .arParcelFitting)
            #expect(defaultValue == false)
        } else {
            Issue.record("Expected isRemoteFeatureFlagEnabled action")
        }
    }

    @Test
    func test_isEligible_when_remote_flag_completes_asynchronously_then_returns_correct_value() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, _, completion):
                Task { completion(true) }
            }
        }
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.arParcelFitting] = true
        let abTestProvider = MockABTestVariationProvider()
        abTestProvider.mockVariationValue = .control

        let sut = ARParcelFittingEligibilityChecker(featureFlagService: featureFlagService,
                                                    abTestVariationProvider: abTestProvider,
                                                    stores: stores,
                                                    isARWorldTrackingSupported: true)

        // When
        let result = await sut.isEligible()

        // Then
        #expect(result == true)
    }
}
