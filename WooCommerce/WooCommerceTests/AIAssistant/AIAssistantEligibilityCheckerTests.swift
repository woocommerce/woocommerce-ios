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
}
