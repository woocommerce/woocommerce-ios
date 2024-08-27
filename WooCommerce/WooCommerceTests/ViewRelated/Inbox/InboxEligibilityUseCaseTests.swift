import XCTest
@testable import WooCommerce

final class InboxEligibilityUseCaseTests: XCTestCase {

    func test_async_isEligibleForInbox_returns_false_when_feature_flag_is_off() {
        // Given
        let siteID: Int64 = 132
        let featureFlagService = MockFeatureFlagService(isInboxOn: false)
        let useCase = InboxEligibilityUseCase(featureFlagService: featureFlagService)

        // When
        let result = useCase.isEligibleForInbox(siteID: siteID)

        // Then
        XCTAssertFalse(result)
    }
}
