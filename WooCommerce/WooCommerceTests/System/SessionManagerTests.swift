import XCTest
@testable import WooCommerce
import Yosemite


/// SessionManager Unit Tests
///
class SessionManagerTests: XCTestCase {

    /// CredentialsStorage Unit-Testing Instance
    ///
    private var manager = SessionManager(defaults: Settings.defaults, keychainServiceName: Settings.keychainServiceName)


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        manager.defaultCredentials = nil
    }

    /// Verifies that `loadDefaultCredentials` returns nil whenever there are no default credentials stored.
    ///
    func testLoadDefaultCredentialsReturnsNilWhenThereAreNoDefaultCredentials() {
        XCTAssertNil(manager.defaultCredentials)
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func testDefaultCredentialsAreProperlyPersistedForWPCOM() {
        manager.defaultCredentials = Settings.wpComCredentials

        let retrieved = manager.defaultCredentials as? WPCOMCredentials
        XCTAssertEqual(retrieved?.authToken, Settings.wpComCredentials.authToken)
        XCTAssertEqual(retrieved?.username, Settings.wpComCredentials.username)
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func testDefaultCredentialsAreProperlyPersistedForWPOrg() {
        manager.defaultCredentials = Settings.wpOrgCredentials

        let retrieved = manager.defaultCredentials as? WPOrgCredentials
        XCTAssertEqual(retrieved?.secret.password, Settings.wpOrgCredentials.secret.password)
        XCTAssertEqual(retrieved?.username, Settings.wpOrgCredentials.username)
    }

    /// Verifies that `removeDefaultCredentials` effectively nukes everything from the keychain
    ///
    func testDefaultCredentialsAreEffectivelyNuked() {
        manager.defaultCredentials = Settings.wpComCredentials
        manager.defaultCredentials = nil

        XCTAssertNil(manager.defaultCredentials)
    }


    /// Verifies that `saveDefaultCredentials` overrides previous stored credentials
    ///
    func testDefaultCredentialsCanBeUpdated() {
        manager.defaultCredentials = Settings.wpComCredentials
        XCTAssertEqual(manager.defaultCredentials as? WPCOMCredentials, Settings.wpComCredentials)

        manager.defaultCredentials = Settings.wpOrgCredentials
        XCTAssertEqual(manager.defaultCredentials as? WPOrgCredentials, Settings.wpOrgCredentials)
    }
}


// MARK: - Testing Constants
//
private enum Settings {
    static let keychainServiceName = "com.automattic.woocommerce.tests"
    static let defaults = UserDefaults(suiteName: "sessionManagerTests")!
    static let wpComCredentials = WPCOMCredentials(username: "lalala", authToken: "1234", siteAddress: "https://example.com")
    static let wpOrgCredentials = WPOrgCredentials(username: "yayaya", password: "5678", siteAddress: "https://wordpress.com")
}
