import Experiments
import Testing
@testable import WooCommerce

struct FeatureFlagServiceWooTests {
    @Test func test_uses_store_design_system_when_feature_flag_is_enabled() {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.storeDesignSystem] = true

        // When, Then
        #expect(featureFlagService.usesStoreDesignSystem)
    }

    @Test func test_does_not_use_store_design_system_when_feature_flag_is_disabled() {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.storeDesignSystem] = false

        // When, Then
        #expect(featureFlagService.usesStoreDesignSystem == false)
    }
}
