import Combine
import XCTest
import Networking
import Observables
@testable import WooCommerce


/// StoresManager Unit Tests
///
class StoresManagerTests: XCTestCase {
    private var observationToken: ObservationToken?
    private var cancellable: AnyCancellable?

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        let session = SessionManager.testingInstance
        session.reset()
    }

    override func tearDown() {
        cancellable?.cancel()
        super.tearDown()
    }

    /// Verifies that the Initial State is Deauthenticated, whenever there are no Default Credentials.
    ///
    func testInitialStateIsDeauthenticatedAssumingCredentialsWereMissing() {
        // Action
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }

        // Assert
        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertEqual(isLoggedInValues, [false])
    }


    /// Verifies that the Initial State is Authenticated, whenever there are Default Credentials set.
    ///
    func testInitialStateIsAuthenticatedAssumingCredentialsWereNotMissing() {
        // Arrange
        let session = SessionManager.testingInstance
        session.defaultCredentials = SessionSettings.credentials

        // Action
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }

        // Assert
        XCTAssertTrue(manager.isAuthenticated)
        XCTAssertEqual(isLoggedInValues, [true])
    }


    /// Verifies that `authenticate(username: authToken:)` effectively switches the Manager to an Authenticated State.
    ///
    func testAuthenticateEffectivelyTogglesStoreManagerToAuthenticatedState() {
        // Arrange
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }

        // Action
        manager.authenticate(credentials: SessionSettings.credentials)

        XCTAssertTrue(manager.isAuthenticated)
        XCTAssertEqual(isLoggedInValues, [false, true])
    }


    /// Verifies that `deauthenticate` effectively switches the Manager to a Deauthenticated State.
    ///
    func testDeauthenticateEffectivelyTogglesStoreManagerToDeauthenticatedState() {
        // Arrange
        let mockAuthenticationManager = MockAuthenticationManager()
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }
        let appCoordinator = AppCoordinator(window: UIWindow(frame: .zero), stores: manager, authenticationManager: mockAuthenticationManager)
        appCoordinator.start()

        // Action
        manager.authenticate(credentials: SessionSettings.credentials)
        manager.deauthenticate()

        // Assert
        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertTrue(mockAuthenticationManager.authenticationUIInvoked)
        XCTAssertEqual(isLoggedInValues, [false, true, false])
    }


    /// Verifies that `authenticate(username: authToken:)` persists the Credentials in the Keychain Storage.
    ///
    func testAuthenticatePersistsDefaultCredentialsInKeychain() {
        let manager = DefaultStoresManager.testingInstance
        manager.authenticate(credentials: SessionSettings.credentials)

        let session = SessionManager.testingInstance
        XCTAssertEqual(session.defaultCredentials, SessionSettings.credentials)
    }

    /// Verifies the user remains authenticated after site switching
    ///
    func testRemoveDefaultStoreLeavesUserAuthenticated() {
        // Arrange
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }

        // Action
        manager.authenticate(credentials: SessionSettings.credentials)
        manager.removeDefaultStore()

        // Assert
        XCTAssertTrue(manager.isAuthenticated)
        XCTAssertEqual(isLoggedInValues, [false, true])
    }

    /// Verify the session manager resets properties after site switching
    ///
    func testRemoveDefaultStoreDeletesSessionManagerDefaultsExceptCredentials() {
        let manager = DefaultStoresManager.testingInstance
        manager.authenticate(credentials: SessionSettings.credentials)

        let session = SessionManager.testingInstance
        manager.removeDefaultStore()

        XCTAssertNotNil(session.defaultCredentials)
        XCTAssertNil(session.defaultAccount)
        XCTAssertNil(session.defaultStoreID)
        XCTAssertNil(session.defaultSite)
    }

    // MARK: `siteID` observable

    func test_siteID_observable_emits_initial_and_subsequent_values_after_authenticating_and_deauthenticating() {
        // Arrange
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        let manager = DefaultStoresManager.testingInstance
        var siteIDValues = [Int64?]()
        observationToken = manager.siteID.subscribe { siteID in
            siteIDValues.append(siteID)
        }

        // Action
        let siteID: Int64 = 134
        manager.updateDefaultStore(storeID: siteID)
        manager.deauthenticate()

        // Assert
        XCTAssertEqual(siteIDValues, [nil, siteID, nil])
    }
}


// MARK: - StoresManager: Testing Methods
//
extension DefaultStoresManager {

    /// Returns a StoresManager instance with testing Keychain/UserDefaults
    ///
    static var testingInstance: DefaultStoresManager {
        return DefaultStoresManager(sessionManager: SessionManager.testingInstance)
    }
}

final class MockAuthenticationManager: AuthenticationManager {
    private(set) var authenticationUIInvoked: Bool = false

    override func authenticationUI() -> UIViewController {
        authenticationUIInvoked = true
        return UIViewController()
    }
}
