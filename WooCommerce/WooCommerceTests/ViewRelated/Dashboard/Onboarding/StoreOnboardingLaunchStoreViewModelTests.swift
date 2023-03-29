import XCTest
@testable import WooCommerce
@testable import Yosemite

final class StoreOnboardingLaunchStoreViewModelTests: XCTestCase {
    private let exampleURL: URL = WooConstants.URLs.privacy.asURL()
    private var stores: MockStoresManager!
    private var sessionManager: SessionManager!
    private let freeTrialID = "1052"

    override func setUp() {
        super.setUp()
        sessionManager = .makeForTesting(authenticated: true)
        stores = MockStoresManager(sessionManager: sessionManager)
    }

    override func tearDown() {
        stores = nil
        sessionManager = nil
        super.tearDown()
    }

    // MARK: - `siteURL`

    func test_siteURL_is_set_from_init_value() throws {
        // Given
        let viewModel = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL, siteID: 1, onLaunch: {}, onUpgradeTapped: {})

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
                },
                                                                    onUpgradeTapped: {})
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
                                                            onLaunch: {},
                                                            onUpgradeTapped: {})

        // When
        await viewModel.launchStore()

        // Then
        XCTAssertEqual(viewModel.error, .alreadyLaunched)
    }

    // MARK: - `canPublishStore`

    func test_canPublishStore_is_false_by_default() async throws {
        // Given
        let siteID: Int64 = 134
        let sut = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL,
                                                      siteID: siteID,
                                                      stores: stores,
                                                      onLaunch: {},
                                                      onUpgradeTapped: {})

        // Then
        XCTAssertFalse(sut.canPublishStore)
    }

    func test_canPublishStore_is_false_for_WPCOM_site_under_free_trail() async {
        // Given
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: true)
        sessionManager.defaultRoles = [.administrator]

        let siteID: Int64 = 134
        let sitePlan = WPComSitePlan(id: self.freeTrialID,
                                     hasDomainCredit: false,
                                     expiryDate: Date().addingDays(14))
        mockLoadSiteCurrentPlan(result: .success(sitePlan))

        let sut = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL,
                                                      siteID: siteID,
                                                      stores: stores,
                                                      onLaunch: {},
                                                      onUpgradeTapped: {})
        // When
        await sut.checkEligibilityToPublishStore()

        // Then
        XCTAssertFalse(sut.canPublishStore)
    }

    func test_canPublishStore_is_true_for_non_WPCOM_site() async {
        // Given
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: false)
        sessionManager.defaultRoles = [.administrator]
        let siteID: Int64 = 134

        let sut = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL,
                                                      siteID: siteID,
                                                      stores: stores,
                                                      onLaunch: {},
                                                      onUpgradeTapped: {})
        // When
        await sut.checkEligibilityToPublishStore()

        // Then
        XCTAssertTrue(sut.canPublishStore)
    }

    func test_canPublishStore_is_true_for_WPCOM_site_not_under_free_trial() async {
        // Given
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: false)
        sessionManager.defaultRoles = [.administrator]
        let siteID: Int64 = 134

        let sitePlan = WPComSitePlan(hasDomainCredit: false)
        mockLoadSiteCurrentPlan(result: .success(sitePlan))

        let sut = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL,
                                                      siteID: siteID,
                                                      stores: stores,
                                                      onLaunch: {},
                                                      onUpgradeTapped: {})
        // When
        await sut.checkEligibilityToPublishStore()

        // Then
        XCTAssertTrue(sut.canPublishStore)
    }

    func test_canPublishStore_is_true_for_WPCOM_site_when_checking_site_plan_fails() async {
        // Given
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: false)
        sessionManager.defaultRoles = [.administrator]
        let siteID: Int64 = 134

        mockLoadSiteCurrentPlan(result: .failure(MockError()))

        let sut = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL,
                                                      siteID: siteID,
                                                      stores: stores,
                                                      onLaunch: {},
                                                      onUpgradeTapped: {})
        // When
        await sut.checkEligibilityToPublishStore()

        // Then
        XCTAssertTrue(sut.canPublishStore)
    }
}

private extension StoreOnboardingLaunchStoreViewModelTests {
    func mockLoadSiteCurrentPlan(result: Result<WPComSitePlan, Error>) {
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            guard case let .loadSiteCurrentPlan(_, completion) = action else {
                return XCTFail()
            }
            completion(result)
        }
    }

    final class MockError: Error { }
}
