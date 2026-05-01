import Experiments
import Testing
import Yosemite
@testable import WooCommerce

struct AIAssistantEligibilityCheckerTests {

    @Test
    func test_isEligible_when_flag_off_then_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = false
        let sut = AIAssistantEligibilityChecker(featureFlagService: flagService)
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
        let sut = AIAssistantEligibilityChecker(featureFlagService: flagService)

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
    func test_isEligible_when_jetpack_connected_then_true() {
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
        #expect(result == true)
    }

    @Test
    func test_isEligible_when_isAIAssistantFeatureActive_then_true() {
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
    func test_isEligible_when_self_hosted_no_jetpack_then_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = AIAssistantEligibilityChecker(featureFlagService: flagService)
        let site = Site.fake().copy(isAIAssistantFeatureActive: false,
                                    isJetpackConnected: false,
                                    isWordPressComStore: false)

        // When
        let result = sut.isEligible(for: site)

        // Then
        #expect(result == false)
    }
}
