import XCTest
import Yosemite
@testable import WooCommerce

final class StoreOnboardingLaunchStoreViewModelTests: XCTestCase {
    private let exampleURL: URL = WooConstants.URLs.privacy.asURL()
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    // MARK: - `siteURL`

    func test_siteURL_is_set_from_init_value() throws {
        // Given
        let viewModel = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL, siteID: 1, onLaunch: {})

        // Then
        XCTAssertEqual(viewModel.siteURL, exampleURL)
    }

    // MARK: - `launchStore`

    func test_launchStore_triggers_onLaunch_on_success() throws {
        // Given
        let siteID: Int64 = 134
        stores.whenReceivingAction(ofType: SiteAction.self) { action in
            guard case let .launchSite(siteIDValue, completion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            guard siteIDValue == siteID else {
                return XCTFail("Launch site with unexpected ID: \(siteIDValue)")
            }
            completion(.success(()))
        }

        // When
        waitFor { promise in
            Task {
                let viewModel = StoreOnboardingLaunchStoreViewModel(siteURL: self.exampleURL,
                                                                    siteID: siteID,
                                                                    stores: self.stores,
                                                                    onLaunch: {
                    // Then
                    promise(())
                })
                await viewModel.launchStore()
            }
        }
    }

    func test_launchStore_sets_alreadyLaunched_error_on_failure() async throws {
        // Given
        let siteID: Int64 = 134
        stores.whenReceivingAction(ofType: SiteAction.self) { action in
            guard case let .launchSite(_, completion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            completion(.failure(.alreadyLaunched))
        }
        let viewModel = StoreOnboardingLaunchStoreViewModel(siteURL: self.exampleURL,
                                                            siteID: siteID,
                                                            stores: self.stores,
                                                            onLaunch: {})

        // When
        await viewModel.launchStore()

        // Then
        XCTAssertEqual(viewModel.error, .alreadyLaunched)
    }
}
