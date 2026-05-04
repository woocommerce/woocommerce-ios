import Experiments
import Testing
import Yosemite
import enum NetworkingCore.Credentials
@testable import WooCommerce

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
    func test_isEligible_when_jetpack_connected_with_wpcom_credentials_then_true() {
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
        #expect(result == true)
    }

    @Test
    func test_isEligible_when_jetpack_connected_with_wporg_credentials_then_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = makeSUT(flagService: flagService, credentials: .wporgFake)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: true,
                                    isWordPressComStore: false)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == false)
    }

    @Test
    func test_isEligible_when_jetpack_connected_with_application_password_credentials_then_true() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = makeSUT(flagService: flagService, credentials: .applicationPasswordFake)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: true,
                                    isWordPressComStore: false)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == true)
    }

    @Test
    func test_isEligible_when_jetpack_connected_with_no_credentials_then_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = makeSUT(flagService: flagService, credentials: nil)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: true,
                                    isWordPressComStore: false)

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
}

private func makeSUT(flagService: MockFeatureFlagService,
                     credentials: Credentials?) -> AIAssistantEligibilityChecker {
    AIAssistantEligibilityChecker(featureFlagService: flagService,
                                  credentialsProvider: { credentials })
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
