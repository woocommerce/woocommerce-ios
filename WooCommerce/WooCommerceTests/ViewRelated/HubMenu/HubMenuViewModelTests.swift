import XCTest

@testable import WooCommerce

final class HubMenuViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 606

    func test_menuElements_do_not_include_inbox_when_feature_flag_is_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(isInboxOn: false)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService)

        // Then
        XCTAssertFalse(viewModel.menuElements.contains(.inbox))
    }

    func test_menuElements_include_inbox_when_feature_flag_is_on() {
        // Given
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)

        // When
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService)

        // Then
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .inbox, .reviews])
    }
}
