import Experiments
import Testing
@testable import WooCommerce

struct AIAssistantEligibilityCheckerTests {

    @Test
    func test_isEligible_when_flag_enabled_then_returns_true() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = true
        let sut = AIAssistantEligibilityChecker(featureFlagService: flagService)

        // When
        let result = sut.isEligible

        // Then
        #expect(result == true)
    }

    @Test
    func test_isEligible_when_flag_disabled_then_returns_false() {
        // Given
        let flagService = MockFeatureFlagService()
        flagService.isFeatureFlagEnabledReturnValue[.wooAIAssistant] = false
        let sut = AIAssistantEligibilityChecker(featureFlagService: flagService)

        // When
        let result = sut.isEligible

        // Then
        #expect(result == false)
    }
}
