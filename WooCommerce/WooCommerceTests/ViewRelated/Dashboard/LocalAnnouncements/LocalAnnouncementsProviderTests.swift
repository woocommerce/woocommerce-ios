import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class LocalAnnouncementsProviderTests: XCTestCase {
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    func test_loadAnnouncement_returns_nil_when_feature_flag_is_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: false)
        let provider = LocalAnnouncementsProvider(stores: stores, featureFlagService: featureFlagService)

        // When
        let announcement = await provider.loadAnnouncement()

        // Then
        XCTAssertNil(announcement)
    }

    func test_loadAnnouncement_returns_nil_when_it_has_been_dismissed() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)
        let provider = LocalAnnouncementsProvider(stores: stores, featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
                case let .getLocalAnnouncementVisibility(announcement, completion):
                    completion(announcement == .productDescriptionAI)
                default:
                    XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let announcement = await provider.loadAnnouncement()

        // Then
        XCTAssertNil(announcement)
    }

    func test_loadAnnouncement_returns_nil_when_site_is_not_wpcom() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)
        stores.updateDefaultStore(storeID: 6)
        stores.updateDefaultStore(.fake().copy(siteID: 6, isWordPressComStore: false))
        let provider = LocalAnnouncementsProvider(stores: stores, featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
                case let .getLocalAnnouncementVisibility(announcement, completion):
                    completion(announcement == .productDescriptionAI)
                default:
                    XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let announcement = await provider.loadAnnouncement()

        // Then
        XCTAssertNil(announcement)
    }

    func test_loadAnnouncement_returns_view_model_when_it_is_visible() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)
        // Sets the prerequisites for the product description AI local announcement.
        stores.updateDefaultStore(storeID: 6)
        stores.updateDefaultStore(.fake().copy(siteID: 6, isWordPressComStore: true))
        let provider = LocalAnnouncementsProvider(stores: stores, featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
                case let .getLocalAnnouncementVisibility(announcement, completion):
                    completion(announcement == .productDescriptionAI)
                default:
                    XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let announcement = await provider.loadAnnouncement()

        // Then
        XCTAssertNotNil(announcement)
    }
}
