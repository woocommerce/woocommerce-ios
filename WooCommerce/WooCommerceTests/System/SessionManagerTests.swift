import XCTest
@testable import WooCommerce
import Yosemite
import KeychainAccess

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
        manager.defaultCredentials = Settings.credentials1

        let retrieved = manager.defaultCredentials
        XCTAssertEqual(retrieved?.authToken, Settings.credentials1.authToken)
        XCTAssertEqual(retrieved?.username, Settings.credentials1.username)
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func testDefaultCredentialsAreProperlyPersistedForWPOrg() {
        manager.defaultCredentials = Settings.credentials2

        let retrieved = manager.defaultCredentials
        XCTAssertEqual(retrieved?.password, Settings.credentials2.password)
        XCTAssertEqual(retrieved?.username, Settings.credentials2.username)
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

    /// Verifies that WPCOM credentials are returned for already installed and logged in versions which don't have type stored in user defaults
    ///
    func test_already_installed_version_without_authentication_type_saved_returns_WPCOM_credentials() {
        let uuid = UUID().uuidString

        // Prepare user defaults
        let defaults = UserDefaults(suiteName: uuid)!
        defaults[UserDefaults.Key.defaultUsername] = "lalala"
        defaults[UserDefaults.Key.defaultSiteAddress] = "https://example.com"

        // Prepare keychain
        let keychainServiceName = uuid
        Keychain(service: keychainServiceName)["lalala"] = "1234"

        // Check that credential type isn't available
        XCTAssertNil(defaults[UserDefaults.Key.defaultCredentialsType])

        let sut = SessionManager(defaults: defaults, keychainServiceName: keychainServiceName)
        XCTAssertEqual(sut.defaultCredentials, Settings.credentials1)
    }
}


// MARK: - Testing Constants
//
private enum Settings {
    static let keychainServiceName = "com.automattic.woocommerce.tests"
    static let defaults = UserDefaults(suiteName: "sessionManagerTests")!
    static let credentials1 = Credentials(username: "lalala", authToken: "1234", siteAddress: "https://example.com")
    static let credentials2 = Credentials(username: "yayaya", password: "5678", siteAddress: "https://wordpress.com")
}
