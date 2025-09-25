import Testing
@testable import PointOfSale

struct POSEntryPointControllerTests {
    @Test func eligibilityState_is_always_eligible_when_i2_feature_is_disabled_regardless_of_eligibility_checker() async throws {
        // Given
        let mockEligibilityChecker = MockPOSEligibilityChecker()
        mockEligibilityChecker.eligibility = .ineligible(reason: .unsupportedIOSVersion)
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)

        // When
        let controller = POSEntryPointController(
            eligibilityChecker: mockEligibilityChecker,
            featureFlagService: featureFlagService
        )

        // Then
        #expect(controller.eligibilityState == .eligible)
    }

    @Test func eligibilityState_is_set_to_ineligible_when_i2_feature_is_enabled_and_checker_returns_ineligible() async throws {
        // Given
        let mockEligibilityChecker = MockPOSEligibilityChecker()
        let expectedState = POSEligibilityState.ineligible(reason: .unsupportedIOSVersion)
        mockEligibilityChecker.eligibility = expectedState
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)

        // When
        let controller = POSEntryPointController(
            eligibilityChecker: mockEligibilityChecker,
            featureFlagService: featureFlagService
        )
        while controller.eligibilityState == nil {
            await Task.yield()
        }

        // Then
        #expect(controller.eligibilityState == expectedState)
    }

    @Test func eligibilityState_is_set_to_eligible_when_i2_feature_is_enabled_and_checker_returns_eligible() async throws {
        // Given
        let mockEligibilityChecker = MockPOSEligibilityChecker()
        mockEligibilityChecker.eligibility = .eligible
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)

        // When
        let controller = POSEntryPointController(
            eligibilityChecker: mockEligibilityChecker,
            featureFlagService: featureFlagService
        )
        while controller.eligibilityState == nil {
            await Task.yield()
        }

        // Then
        #expect(controller.eligibilityState == .eligible)
    }
}
