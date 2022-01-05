import Codegen
import Combine
import XCTest
import Networking
@testable import WooCommerce


/// StoresManager Unit Tests
///
final class StoresManagerTests: XCTestCase {
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
        cancellable = manager.siteID.sink { siteID in
            siteIDValues.append(siteID)
        }

        // Action
        let siteID: Int64 = 134
        manager.updateDefaultStore(storeID: siteID)
        manager.deauthenticate()

        // Assert
        XCTAssertEqual(siteIDValues, [nil, siteID, nil])
    }

    // MARK: `updateDefaultStore(_ site: Site)`

    func test_updateDefaultStore_with_the_same_siteID_updates_site_but_does_not_emit_siteID() {
        // Arrange
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        let manager = DefaultStoresManager.testingInstance
        var siteIDValues = [Int64?]()
        cancellable = manager.siteID.sink { siteID in
            siteIDValues.append(siteID)
        }
        let siteID: Int64 = 134

        // Action
        // Default site ID needs to be set before the site can be updated.
        manager.updateDefaultStore(storeID: siteID)

        let jcpSite = Site.fake().copy(siteID: siteID, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        manager.updateDefaultStore(jcpSite)
        let siteIDValuesAfterUpdatingWithJCPSite = siteIDValues

        let jetpackSite = Site.fake().copy(siteID: siteID, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        manager.updateDefaultStore(jetpackSite)
        let siteIDValuesAfterUpdatingWithJetpackSite = siteIDValues

        // Assert
        XCTAssertEqual(siteIDValuesAfterUpdatingWithJCPSite, [nil, siteID])
        XCTAssertEqual(siteIDValuesAfterUpdatingWithJetpackSite, [nil, siteID])
        XCTAssertEqual(manager.sessionManager.defaultSite, jetpackSite)
    }

    func test_updateDefaultStore_with_site_of_a_different_siteID_does_not_update_site_nor_emit_siteID() {
        // Arrange
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        let manager = DefaultStoresManager.testingInstance
        var siteIDValues = [Int64?]()
        cancellable = manager.siteID.sink { siteID in
            siteIDValues.append(siteID)
        }

        // Action
        let siteID: Int64 = 134
        manager.updateDefaultStore(storeID: siteID)

        let differentSiteID: Int64 = 256
        let differentSite = Site.fake().copy(siteID: differentSiteID, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        manager.updateDefaultStore(differentSite)

        // Assert
        XCTAssertEqual(siteIDValues, [nil, siteID])
        XCTAssertNil(manager.sessionManager.defaultSite)
    }

    func test_updateDefaultStore_with_site_without_setting_previous_siteID_does_not_update_site_nor_emit_siteID() {
        // Arrange
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        let manager = DefaultStoresManager.testingInstance
        var siteIDValues = [Int64?]()
        cancellable = manager.siteID.sink { siteID in
            siteIDValues.append(siteID)
        }

        // Action
        let siteID: Int64 = 134
        let site = Site.fake().copy(siteID: siteID, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        manager.updateDefaultStore(site)

        // Assert
        XCTAssertEqual(siteIDValues, [nil])
        XCTAssertNil(manager.sessionManager.defaultSite)
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
