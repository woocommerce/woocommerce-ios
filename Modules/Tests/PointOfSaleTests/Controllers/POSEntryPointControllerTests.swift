import Testing
@testable import PointOfSale

struct POSEntryPointControllerTests {
    @Test func eligibilityState_is_set_to_ineligible_when_checker_returns_ineligible() async throws {
        // Given
        let mockEligibilityChecker = MockPOSEligibilityChecker()
        let expectedState = POSEligibilityState.ineligible(reason: .featureSwitchDisabled)
        mockEligibilityChecker.eligibility = expectedState

        // When
        let controller = POSEntryPointController(
            eligibilityChecker: mockEligibilityChecker
        )
        while controller.eligibilityState == nil {
            await Task.yield()
        }

        // Then
        #expect(controller.eligibilityState == expectedState)
    }

    @Test func eligibilityState_is_set_to_eligible_when_checker_returns_eligible() async throws {
        // Given
        let mockEligibilityChecker = MockPOSEligibilityChecker()
        mockEligibilityChecker.eligibility = .eligible

        // When
        let controller = POSEntryPointController(
            eligibilityChecker: mockEligibilityChecker
        )
        while controller.eligibilityState == nil {
            await Task.yield()
        }

        // Then
        #expect(controller.eligibilityState == .eligible)
    }
}
