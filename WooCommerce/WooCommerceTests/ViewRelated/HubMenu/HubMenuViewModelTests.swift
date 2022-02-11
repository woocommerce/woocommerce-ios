import XCTest

@testable import WooCommerce
@testable import Yosemite

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
        viewModel.setupMenuElements()

        // Then
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .inbox, .reviews])
    }

    func test_menuElements_include_coupons_when_couponManagement_is_enabled_in_app_settings() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let featureFlagService = MockFeatureFlagService(isInboxOn: true)

        // When
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadCouponManagementFeatureSwitchState(let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService, stores: stores)
        viewModel.setupMenuElements()

        // Then
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .inbox, .coupons, .reviews])
    }

    func test_menuElements_does_not_include_coupons_when_couponManagement_is_not_enabled_in_app_settings() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let featureFlagService = MockFeatureFlagService(isInboxOn: false)

        // When
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadCouponManagementFeatureSwitchState(let onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        let viewModel = HubMenuViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService, stores: stores)
        viewModel.setupMenuElements()

        // Then
        XCTAssertEqual(viewModel.menuElements, [.woocommerceAdmin, .viewStore, .reviews])
    }
}
