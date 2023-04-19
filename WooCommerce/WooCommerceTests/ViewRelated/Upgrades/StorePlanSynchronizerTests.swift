import XCTest
@testable import WooCommerce
@testable import Yosemite

final class StorePlanSynchronizerTests: XCTestCase {

    // Mocked stores manager
    var stores = MockStoresManager(sessionManager: .testingInstance)

    // Mocked session
    var session = SessionManager.makeForTesting()

    // Site ID
    let sampleSiteID: Int64 = 123

    override func setUp() {
        session = SessionManager.makeForTesting(authenticated: true, isWPCom: true)
        session.defaultSite = .fake().copy(siteID: sampleSiteID, isWordPressComStore: true)
        stores = MockStoresManager(sessionManager: session)

        super.setUp()
    }

    func test_synchronizer_has_not_loaded_state_if_there_is_not_a_site() {
        // Given
        session.defaultSite = nil

        // When
        let synchronizer = StorePlanSynchronizer(stores: stores)

        // Then
        XCTAssertEqual(synchronizer.planState, .notLoaded)
    }

    func test_synchronizer_has_unavailable_state_on_a_non_wpcom_site() {
        // Given
        session.defaultSite = .fake().copy(siteID: sampleSiteID)

        // When
        let synchronizer = StorePlanSynchronizer(stores: stores)

        // Then
        XCTAssertEqual(synchronizer.planState, .unavailable)
    }

    func test_synchronizer_fetches_plan_immediately_if_there_is_a_wpcom_site() {
        // Given
        let samplePlan = WPComSitePlan(hasDomainCredit: false)
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(samplePlan))
            default:
                break
            }
        }

        // When
        let synchronizer = StorePlanSynchronizer(stores: stores)

        // Then
        XCTAssertEqual(synchronizer.planState, .loaded(samplePlan))
    }

    func test_synchronizer_reflects_error_state() {
        // Given
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
            default:
                break
            }
        }

        // When
        let synchronizer = StorePlanSynchronizer(stores: stores)

        // Then
        XCTAssertEqual(synchronizer.planState, .failed)
    }
}
