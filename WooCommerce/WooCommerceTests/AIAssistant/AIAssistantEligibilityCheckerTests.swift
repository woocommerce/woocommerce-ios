import Experiments
import Testing
import Yosemite
@testable import WooCommerce

@Suite(.timeLimit(.minutes(1)))
struct AIAssistantEligibilityCheckerTests {

    @Test
    func test_isEligible_when_feature_flag_off_then_returns_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = false
        let sut = AIAssistantEligibilityChecker(featureFlagService: flagService)
        let site = Site.fake().copy(isAIAssistantFeatureActive: true, isWordPressComStore: true)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == false)
    }

    @Test
    func test_isEligible_when_feature_flag_on_and_site_nil_then_returns_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = AIAssistantEligibilityChecker(featureFlagService: flagService)

        // When
        let result = sut.isEligible(for: nil)

        // Then
        #expect(result == false)
    }

    @Test
    func test_isEligible_when_feature_flag_on_and_site_is_wpcom_then_returns_true() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = AIAssistantEligibilityChecker(featureFlagService: flagService)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: false,
                                    isWordPressComStore: true)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == true)
    }

    @Test
    func test_isEligible_when_feature_flag_on_and_site_has_ai_feature_active_then_returns_true() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = AIAssistantEligibilityChecker(featureFlagService: flagService)
        let site = Site.fake().copy(isAIAssistantFeatureActive: true,
                                    isJetpackConnected: false,
                                    isWordPressComStore: false)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == true)
    }

    @Test
    func test_isEligible_when_feature_flag_on_and_site_is_jetpack_only_then_returns_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = AIAssistantEligibilityChecker(featureFlagService: flagService)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: true,
                                    isWordPressComStore: false)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == false)
    }

    @Test
    func test_async_isEligible_when_local_check_fails_then_returns_false_without_dispatching() async {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = false
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let sut = makeSUT(flagService: flagService, stores: stores)
        let site = Site.fake().copy(isWordPressComStore: true)

        // When
        let result = await sut.isEligible(for: site, useCache: true)

        // Then
        #expect(result == false)
        #expect(stores.receivedActions.isEmpty)
    }

    @Test
    func test_async_isEligible_when_local_eligible_and_remote_enabled_then_true() async {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, _, onCompletion):
                onCompletion(true)
            }
        }
        let sut = makeSUT(flagService: flagService, stores: stores)
        let site = Site.fake().copy(isWordPressComStore: true)

        // When
        let result = await sut.isEligible(for: site, useCache: true)

        // Then
        #expect(result == true)
    }

    @Test
    func test_async_isEligible_when_local_eligible_and_remote_disabled_then_false() async {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, _, onCompletion):
                onCompletion(false)
            }
        }
        let sut = makeSUT(flagService: flagService, stores: stores)
        let site = Site.fake().copy(isWordPressComStore: true)

        // When
        let result = await sut.isEligible(for: site, useCache: true)

        // Then
        #expect(result == false)
    }

    @Test
    func test_async_isEligible_when_local_eligible_and_useCache_false_then_dispatches_with_useCache_false() async {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, _, onCompletion):
                onCompletion(true)
            }
        }
        let sut = makeSUT(flagService: flagService, stores: stores)
        let site = Site.fake().copy(isWordPressComStore: true)

        // When
        _ = await sut.isEligible(for: site, useCache: false)

        // Then
        let dispatched = stores.receivedActions.compactMap { $0 as? FeatureFlagAction }
        #expect(dispatched.count == 1)
        if case let .isRemoteFeatureFlagEnabled(flag, _, useCache, _) = dispatched.first {
            #expect(flag == .wooAIAssistant)
            #expect(useCache == false)
        } else {
            Issue.record("Expected isRemoteFeatureFlagEnabled action to be dispatched")
        }
    }

    @Test
    func test_async_isEligible_uses_useCache_true_by_default() async {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, _, onCompletion):
                onCompletion(true)
            }
        }
        let sut = makeSUT(flagService: flagService, stores: stores)
        let site = Site.fake().copy(isWordPressComStore: true)

        // When
        _ = await sut.isEligible(for: site)

        // Then
        let dispatched = stores.receivedActions.compactMap { $0 as? FeatureFlagAction }
        #expect(dispatched.count == 1)
        if case let .isRemoteFeatureFlagEnabled(_, _, useCache, _) = dispatched.first {
            #expect(useCache == true)
        } else {
            Issue.record("Expected isRemoteFeatureFlagEnabled action to be dispatched")
        }
    }

    @Test
    func test_async_isEligible_when_remote_action_uses_defaultValue_true() async {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, _, onCompletion):
                onCompletion(true)
            }
        }
        let sut = makeSUT(flagService: flagService, stores: stores)
        let site = Site.fake().copy(isWordPressComStore: true)

        // When
        _ = await sut.isEligible(for: site, useCache: true)

        // Then
        let dispatched = stores.receivedActions.compactMap { $0 as? FeatureFlagAction }
        if case let .isRemoteFeatureFlagEnabled(_, defaultValue, _, _) = dispatched.first {
            #expect(defaultValue == true)
        } else {
            Issue.record("Expected isRemoteFeatureFlagEnabled action to be dispatched")
        }
    }
}

private func makeSUT(flagService: MockFeatureFlagService,
                     stores: StoresManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))) -> AIAssistantEligibilityChecker {
    AIAssistantEligibilityChecker(featureFlagService: flagService, stores: stores)
}
