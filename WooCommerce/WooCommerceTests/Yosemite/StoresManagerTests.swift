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
        let manager = StoresManager.testingInstance
        XCTAssertFalse(manager.isAuthenticated)
    }


    /// Verifies that the Initial State is Authenticated, whenever there are Default Credentials set.
    ///
    func testInitialStateIsAuthenticatedAssumingCredentialsWereNotMissing() {
        var session = SessionManager.testingInstance
        session.defaultCredentials = Settings.credentials

        let manager = StoresManager.testingInstance
        XCTAssertTrue(manager.isAuthenticated)
    }


    /// Verifies that `authenticate(username: authToken:)` effectively switches the Manager to an Authenticated State.
    ///
    func testAuthenticateEffectivelyTogglesStoreManagerToAuthenticatedState() {
        let manager = StoresManager.testingInstance
        manager.authenticate(username: Settings.credentials.username, authToken: Settings.credentials.authToken, onCompletion: nil)

        XCTAssertTrue(manager.isAuthenticated)
    }


    /// Verifies that `deauthenticate` effectively switches the Manager to a Deauthenticated State.
    ///
    func testDeauthenticateEffectivelyTogglesStoreManagerToDeauthenticatedState() {
        let manager = StoresManager.testingInstance
        manager.authenticate(username: Settings.credentials.username, authToken: Settings.credentials.authToken)
        manager.deauthenticate()

        XCTAssertFalse(manager.isAuthenticated)
    }


    /// Verifies that `authenticate(username: authToken:)` persists the Credentials in the Keychain Storage.
    ///
    func testAuthenticatePersistsDefaultCredentialsInKeychain() {
        let manager = StoresManager.testingInstance
        manager.authenticate(username: Settings.credentials.username, authToken: Settings.credentials.authToken)

        let session = SessionManager.testingInstance
        XCTAssertEqual(session.defaultCredentials, Settings.credentials)
    }
}


// MARK: - SessionManager: Testing Methods
//
private extension SessionManager {

    /// Returns a SessionManager instance with testing Keychain/UserDefaults
    ///
    static var testingInstance: SessionManager {
        return SessionManager(defaults: Settings.defaults, keychainServiceName: Settings.keychainServiceName)
    }
}


// MARK: - StoresManager: Testing Methods
//
private extension StoresManager {

    /// Returns a StoresManager instance with testing Keychain/UserDefaults
    ///
    static var testingInstance: StoresManager {
        return StoresManager(sessionManager: .testingInstance)
    }
}


// MARK: - Testing Constants
//
private enum Settings {
    static let credentials = Credentials(username: "username", authToken: "authToken")
    static let defaults = UserDefaults(suiteName: "storesManagerTests")!
    static let keychainServiceName = "com.woocommerce.storesmanagertests"
}
