import XCTest
import Networking
@testable import WooCommerce


/// StoresManager Unit Tests
///
class StoresManagerTests: XCTestCase {

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        initializeTestingSession().reset()
    }


    /// Verifies that the Initial State is Deauthenticated, whenever there are no Default Credentials.
    ///
    func testInitialStateIsDeauthenticatedAssumingCredentialsWereMissing() {
        let manager = initializeTestingStoresManager()
        XCTAssertFalse(manager.isAuthenticated)
    }


    /// Verifies that the Initial State is Authenticated, whenever there are Default Credentials set.
    ///
    func testInitialStateIsAuthenticatedAssumingCredentialsWereNotMissing() {
        let session = initializeTestingSession()
        session.credentials = Settings.credentials

        let manager = initializeTestingStoresManager()
        XCTAssertTrue(manager.isAuthenticated)
    }


    /// Verifies that `authenticate(username: authToken:)` effectively switches the Manager to an Authenticated State.
    ///
    func testAuthenticateEffectivelyTogglesStoreManagerToAuthenticatedState() {
        let manager = initializeTestingStoresManager()
        manager.authenticate(username: Settings.credentials.username, authToken: Settings.credentials.authToken)

        XCTAssertTrue(manager.isAuthenticated)
    }


    /// Verifies that `deauthenticate` effectively switches the Manager to a Deauthenticated State.
    ///
    func testDeauthenticateEffectivelyTogglesStoreManagerToDeauthenticatedState() {
        let manager = initializeTestingStoresManager()
        manager.authenticate(username: Settings.credentials.username, authToken: Settings.credentials.authToken)
        manager.deauthenticate()

        XCTAssertFalse(manager.isAuthenticated)
    }


    /// Verifies that `authenticate(username: authToken:)` persists the Credentials in the Keychain Storage.
    ///
    func testAuthenticatePersistsDefaultCredentialsInKeychain() {
        let manager = initializeTestingStoresManager()
        manager.authenticate(username: Settings.credentials.username, authToken: Settings.credentials.authToken)

        let session = initializeTestingSession()
        XCTAssertEqual(session.credentials, Settings.credentials)
    }
}


// MARK: - Private Methods
//
private extension StoresManagerTests {

    /// Returns a Session instance with testing Keychain/UserDefaults
    ///
    func initializeTestingSession() -> Session {
        return Session(keychainServiceName: Settings.keychainServiceName, defaultsStorage: Settings.defaultsStorage)
    }

    /// Returns a StoresManager instance with testing Keychain/UserDefaults
    ///
    func initializeTestingStoresManager() -> StoresManager {
        return StoresManager(keychainServiceName: Settings.keychainServiceName, defaultsStorage: Settings.defaultsStorage)
    }
}


// MARK: - Nested Types
//
private enum Settings {
    static let credentials = Credentials(username: "username", authToken: "authToken")
    static let defaultsStorage = UserDefaults(suiteName: "testingKeychainServiceName")!
    static let keychainServiceName = "com.woocommerce.storesmanagertests"
}
