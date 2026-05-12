import Experiments
import Testing
import Yosemite
import enum NetworkingCore.Credentials
@testable import WooCommerce

@Suite(.timeLimit(.minutes(1)))
struct AIAssistantEligibilityCheckerTests {

    @Test
    func test_isEligible_when_flag_off_then_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = false
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake)
        let site = Site.fake().copy(isWordPressComStore: true)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == false)
    }

    @Test
    func test_isEligible_when_site_nil_then_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake)

        // When
        let result = sut.isEligible(for: nil)

        // Then
        #expect(result == false)
    }

    @Test
    func test_isEligible_when_wpcom_site_then_true() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: false,
                                    isWordPressComStore: true)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == true)
    }

    @Test
    func test_isEligible_when_jetpack_connected_only_with_wpcom_credentials_then_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: true,
                                    isWordPressComStore: false)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == false)
    }

    @Test
    func test_isEligible_when_wpcom_store_with_application_password_credentials_then_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = makeSUT(flagService: flagService, credentials: .applicationPasswordFake)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: true,
                                    isWordPressComStore: true)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == false)
    }

    @Test
    func test_isEligible_when_wpcom_store_with_wporg_credentials_then_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = makeSUT(flagService: flagService, credentials: .wporgFake)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: true,
                                    isWordPressComStore: true)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == false)
    }

    @Test
    func test_isEligible_when_wpcom_store_with_no_credentials_then_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = makeSUT(flagService: flagService, credentials: nil)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: true,
                                    isWordPressComStore: true)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == false)
    }

    @Test
    func test_isEligible_when_isAIAssistantFeatureActive_then_true() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake)
        let site = Site.fake().copy(isAIAssistantFeatureActive: true,
                                    isJetpackConnected: false,
                                    isWordPressComStore: false)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == true)
    }

    @Test
    func test_isEligible_when_self_hosted_no_jetpack_then_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: false,
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
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake, stores: stores)
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
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake, stores: stores)
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
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake, stores: stores)
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
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake, stores: stores)
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
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake, stores: stores)
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
        let sut = makeSUT(flagService: flagService, credentials: .wpcomFake, stores: stores)
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
                     credentials: Credentials?,
                     stores: StoresManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))) -> AIAssistantEligibilityChecker {
    AIAssistantEligibilityChecker(featureFlagService: flagService,
                                  credentialsProvider: { credentials },
                                  stores: stores)
}

private extension Credentials {
    static let wpcomFake: Credentials = .wpcom(username: "user",
                                               authToken: "token",
                                               siteAddress: "https://example.com")
    static let wporgFake: Credentials = .wporg(username: "user",
                                               password: "password",
                                               siteAddress: "https://example.com")
    static let applicationPasswordFake: Credentials = .applicationPassword(username: "user",
                                                                           password: "password",
                                                                           siteAddress: "https://example.com")
}
