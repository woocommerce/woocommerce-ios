import XCTest
import Networking
@testable import WooCommerce


/// StoresManager Unit Tests
///
class StoresManagerTests: XCTestCase {

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        var session = SessionManager.testingInstance
        session.reset()
    }


    /// Verifies that the Initial State is Deauthenticated, whenever there are no Default Credentials.
    ///
    func testInitialStateIsDeauthenticatedAssumingCredentialsWereMissing() {
        let manager = DefaultStoresManager.testingInstance
        XCTAssertFalse(manager.isAuthenticated)
    }


    /// Verifies that the Initial State is Authenticated, whenever there are Default Credentials set.
    ///
    func testInitialStateIsAuthenticatedAssumingCredentialsWereNotMissing() {
        var session = SessionManager.testingInstance
        session.defaultCredentials = SessionSettings.credentials

        let manager = DefaultStoresManager.testingInstance
        XCTAssertTrue(manager.isAuthenticated)
    }


    /// Verifies that `authenticate(username: authToken:)` effectively switches the Manager to an Authenticated State.
    ///
    func testAuthenticateEffectivelyTogglesStoreManagerToAuthenticatedState() {
        let manager = DefaultStoresManager.testingInstance
        manager.authenticate(credentials: SessionSettings.credentials)

        XCTAssertTrue(manager.isAuthenticated)
    }


    /// Verifies that `deauthenticate` effectively switches the Manager to a Deauthenticated State.
    ///
    func testDeauthenticateEffectivelyTogglesStoreManagerToDeauthenticatedState() {
        let manager = DefaultStoresManager.testingInstance
        manager.authenticate(credentials: SessionSettings.credentials)
        manager.deauthenticate()

        XCTAssertFalse(manager.isAuthenticated)
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
        let manager = DefaultStoresManager.testingInstance
        manager.authenticate(credentials: SessionSettings.credentials)
        manager.removeDefaultStore()

        XCTAssertTrue(manager.isAuthenticated)
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
}


// MARK: - StoresManager: Testing Methods
//
extension DefaultStoresManager {

    /// Returns a StoresManager instance with testing Keychain/UserDefaults
    ///
    static var testingInstance: DefaultStoresManager {
        return DefaultStoresManager(sessionManager: .testingInstance)
    }
}
