import XCTest
import Networking
@testable import WooCommerce


/// StoresManager Unit Tests
///
class StoresManagerTests: XCTestCase {

    /// Default Credentials
    ///
    private let defaultCredentials = Credentials(username: "username", authToken: "authToken")

    /// Unit Testing Keychain
    ///
    private let keychain = CredentialsManager(serviceName: "com.woocommerce.storesmanagertests")

    /// StoresManager Testing Instance
    ///
    private var manager: StoresManager!


    // MARK: - Overridden Methods
    override func setUp() {
        super.setUp()
        keychain.removeDefaultCredentials()
        manager = StoresManager(keychain: keychain)
    }


    /// Verifies that the Initial State is Deauthenticated, whenever there are no Default Credentials.
    ///
    func testInitialStateIsDeauthenticatedAssumingCredentialsWereMissing() {
        XCTAssertTrue(keychain.needsDefaultCredentials)
        XCTAssertFalse(manager.isAuthenticated)
    }


    /// Verifies that the Initial State is Authenticated, whenever there are Default Credentials set.
    ///
    func testInitialStateIsAuthenticatedAssumingCredentialsWereNotMissing() {
        keychain.saveDefaultCredentials(defaultCredentials)
        XCTAssertFalse(keychain.needsDefaultCredentials)

        manager = StoresManager(keychain: keychain)
        XCTAssertTrue(manager.isAuthenticated)
    }


    /// Verifies that `authenticate(username: authToken:)` effectively switches the Manager to an Authenticated State.
    ///
    func testAuthenticateEffectivelyTogglesStoreManagerToAuthenticatedState() {
        manager.authenticate(username: defaultCredentials.username, authToken: defaultCredentials.authToken)
        XCTAssertTrue(manager.isAuthenticated)
    }


    /// Verifies that `deauthenticate` effectively switches the Manager to a Deauthenticated State.
    ///
    func testDeauthenticateEffectivelyTogglesStoreManagerToDeauthenticatedState() {
        manager.authenticate(username: defaultCredentials.username, authToken: defaultCredentials.authToken)
        manager.deauthenticate()
        XCTAssertFalse(manager.isAuthenticated)
    }


    /// Verifies that `authenticate(username: authToken:)` persists the Credentials in the Keychain Storage.
    ///
    func testAuthenticatePersistsDefaultCredentialsInKeychain() {
        XCTAssertTrue(keychain.needsDefaultCredentials)
        manager.authenticate(username: defaultCredentials.username, authToken: defaultCredentials.authToken)

        let credentials = keychain.loadDefaultCredentials()
        XCTAssertEqual(credentials, defaultCredentials)
    }
}
