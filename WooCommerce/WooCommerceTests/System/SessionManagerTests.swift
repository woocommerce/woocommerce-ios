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
    func testDefaultCredentialsAreProperlyPersisted() {
        manager.defaultCredentials = Settings.credentials1

        let retrieved = manager.defaultCredentials
        XCTAssertEqual(retrieved?.authToken, Settings.credentials1.authToken)
        XCTAssertEqual(retrieved?.username, Settings.credentials1.username)
    }


    /// Verifies that `removeDefaultCredentials` effectively nukes everything from the keychain
    ///
    func testDefaultCredentialsAreEffectivelyNuked() {
        manager.defaultCredentials = Settings.credentials1
        manager.defaultCredentials = nil

        XCTAssertNil(manager.defaultCredentials)
    }


    /// Verifies that `saveDefaultCredentials` overrides previous stored credentials
    ///
    func testDefaultCredentialsCanBeUpdated() {
        manager.defaultCredentials = Settings.credentials1
        XCTAssertEqual(manager.defaultCredentials, Settings.credentials1)

        manager.defaultCredentials = Settings.credentials2
        XCTAssertEqual(manager.defaultCredentials, Settings.credentials2)
    }
}


// MARK: - Testing Constants
//
private enum Settings {
    static let keychainServiceName = "com.automattic.woocommerce.tests"
    static let defaults = UserDefaults(suiteName: "sessionManagerTests")!
    static let credentials1 = Credentials(username: "lalala", authToken: "1234", siteAddress: "https://example.com")
    static let credentials2 = Credentials(username: "yayaya", authToken: "5678", siteAddress: "https://wordpress.com")
}
