import XCTest
@testable import WooCommerce
@testable import Yosemite

final class StoreOnboardingLaunchStoreViewModelTests: XCTestCase {
    private let exampleURL: URL = WooConstants.URLs.privacy.asURL()
    private var stores: MockStoresManager!
    private var sessionManager: SessionManager!
    private let freeTrialID = "1052"
    private let siteID: Int64 = 134

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
        let viewModel = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL, siteID: 1, onLaunch: {}, onLearnMoreTapped: {})

        // Then
        XCTAssertEqual(viewModel.siteURL, exampleURL)
    }

    // MARK: - `launchStore`

    func test_launchStore_triggers_onLaunch_on_success() throws {
        // Given
        stores.whenReceivingAction(ofType: SiteAction.self) { action in
            guard case let .launchSite(siteIDValue, completion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            guard siteIDValue == self.siteID else {
                return XCTFail("Launch site with unexpected ID: \(siteIDValue)")
            }
            completion(.success(()))
        }

        // When
        waitFor { promise in
            Task {
                let viewModel = StoreOnboardingLaunchStoreViewModel(siteURL: self.exampleURL,
                                                                    siteID: self.siteID,
                                                                    stores: self.stores,
                                                                    onLaunch: {
                    // Then
                    promise(())
                },
                                                                    onLearnMoreTapped: {})
                await viewModel.launchStore()
            }
        }
    }

    func test_launchStore_sets_alreadyLaunched_error_on_failure() async throws {
        // Given
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
                                                            onLearnMoreTapped: {})

        // When
        await viewModel.launchStore()

        // Then
        XCTAssertEqual(viewModel.error, .alreadyLaunched)
    }

    func test_launchStore_updates_state_to_launchingStore_when_there_is_no_error() async throws {
        // Given
        stores.whenReceivingAction(ofType: SiteAction.self) { action in
            guard case let .launchSite(_, completion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            completion(.success(()))
        }

        let sut = StoreOnboardingLaunchStoreViewModel(siteURL: self.exampleURL,
                                                      siteID: siteID,
                                                      stores: self.stores,
                                                      onLaunch: {},
                                                      onLearnMoreTapped: {})
        // When
        await sut.launchStore()

        // Then
        XCTAssertEqual(sut.state, .launchingStore)
    }

    func test_launchStore_updates_state_to_readyToPublish_when_there_is_error() async throws {
        // Given
        stores.whenReceivingAction(ofType: SiteAction.self) { action in
            guard case let .launchSite(_, completion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            completion(.failure(SiteLaunchError.unexpected(description: "mock")))
        }

        let sut = StoreOnboardingLaunchStoreViewModel(siteURL: self.exampleURL,
                                                      siteID: siteID,
                                                      stores: self.stores,
                                                      onLaunch: {},
                                                      onLearnMoreTapped: {})
        // When
        await sut.launchStore()

        // Then
        XCTAssertEqual(sut.state, .readyToPublish)
    }

    // MARK: - `state`

    func test_state_is_checkingSitePlan_by_default() async throws {
        // Given
        let sut = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL,
                                                      siteID: siteID,
                                                      stores: stores,
                                                      onLaunch: {},
                                                      onLearnMoreTapped: {})

        // Then
        XCTAssertEqual(sut.state, .checkingSitePlan)
    }

    func test_state_is_needsPlanUpgrade_for_WPCOM_site_under_free_trail() async {
        // Given
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: true)
        sessionManager.defaultRoles = [.administrator]

        let sitePlan = WPComSitePlan(id: self.freeTrialID,
                                     hasDomainCredit: false,
                                     expiryDate: Date().addingDays(14))
        mockLoadSiteCurrentPlan(result: .success(sitePlan))

        let sut = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL,
                                                      siteID: siteID,
                                                      stores: stores,
                                                      onLaunch: {},
                                                      onLearnMoreTapped: {})
        // When
        await sut.checkEligibilityToPublishStore()

        // Then
        XCTAssertEqual(sut.state, .needsPlanUpgrade)
    }

    func test_state_is_readyToPublish_for_WPCOM_site_not_under_free_trial() async {
        // Given
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: true)
        sessionManager.defaultRoles = [.administrator]

        let sitePlan = WPComSitePlan(hasDomainCredit: false)
        mockLoadSiteCurrentPlan(result: .success(sitePlan))

        let sut = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL,
                                                      siteID: siteID,
                                                      stores: stores,
                                                      onLaunch: {},
                                                      onLearnMoreTapped: {})
        // When
        await sut.checkEligibilityToPublishStore()

        // Then
        XCTAssertEqual(sut.state, .readyToPublish)
    }

    func test_state_is_readyToPublish_for_WPCOM_site_when_checking_site_plan_fails() async {
        // Given
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: true)
        sessionManager.defaultRoles = [.administrator]

        mockLoadSiteCurrentPlan(result: .failure(MockError()))

        let sut = StoreOnboardingLaunchStoreViewModel(siteURL: exampleURL,
                                                      siteID: siteID,
                                                      stores: stores,
                                                      onLaunch: {},
                                                      onLearnMoreTapped: {})
        // When
        await sut.checkEligibilityToPublishStore()

        // Then
        XCTAssertEqual(sut.state, .readyToPublish)
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
