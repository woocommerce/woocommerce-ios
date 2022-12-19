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
        // Given
        manager.defaultCredentials = Settings.wpcomCredentials

        guard case let .wpcom(username: username, authToken: authToken, siteAddress: siteAddress) = manager.defaultCredentials else {
            XCTFail("Missing credentials.")
            return
        }

        // When
        let retrieved = Credentials(username: username, authToken: authToken, siteAddress: siteAddress)

        // Then
        XCTAssertEqual(retrieved, Settings.wpcomCredentials)
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func testDefaultCredentialsAreProperlyPersistedForWPOrg() {
        // Given
        manager.defaultCredentials = Settings.wporgCredentials

        guard case let .wporg(username: username, password: password, siteAddress: siteAddress) = manager.defaultCredentials else {
            XCTFail("Missing credentials.")
            return
        }

        // When
        let retrieved = Credentials(username: username, password: password, siteAddress: siteAddress)

        // Then
        XCTAssertEqual(retrieved, Settings.wporgCredentials)
    }

    /// Verifies that `removeDefaultCredentials` effectively nukes everything from the keychain
    ///
    func testDefaultCredentialsAreEffectivelyNuked() {
        manager.defaultCredentials = Settings.wpcomCredentials
        manager.defaultCredentials = nil

        XCTAssertNil(manager.defaultCredentials)
    }

    /// Verifies that `saveDefaultCredentials` overrides previous stored credentials
    ///
    func testDefaultCredentialsCanBeUpdated() {
        manager.defaultCredentials = Settings.wpcomCredentials
        XCTAssertEqual(manager.defaultCredentials, Settings.wpcomCredentials)

        manager.defaultCredentials = Settings.wporgCredentials
        XCTAssertEqual(manager.defaultCredentials, Settings.wporgCredentials)
    }

    /// Verifies that WPCOM credentials are returned for already installed and logged in versions which don't have type stored in user defaults
    ///
    func test_already_installed_version_without_authentication_type_saved_returns_WPCOM_credentials() {
        // Given
        let uuid = UUID().uuidString

        // Prepare user defaults
        let defaults = UserDefaults(suiteName: uuid)!
        defaults[UserDefaults.Key.defaultUsername] = "lalala"
        defaults[UserDefaults.Key.defaultSiteAddress] = "https://example.com"

        // Prepare keychain
        let keychainServiceName = uuid
        Keychain(service: keychainServiceName)["lalala"] = "1234"

        // When

        // Check that credential type isn't available
        XCTAssertNil(defaults[UserDefaults.Key.defaultCredentialsType])

        let sut = SessionManager(defaults: defaults, keychainServiceName: keychainServiceName)

        // Then
        XCTAssertEqual(sut.defaultCredentials, Settings.wpcomCredentials)
    }
}


// MARK: - Testing Constants
//
private enum Settings {
    static let keychainServiceName = "com.automattic.woocommerce.tests"
    static let defaults = UserDefaults(suiteName: "sessionManagerTests")!
    static let wpcomCredentials = Credentials(username: "lalala", authToken: "1234", siteAddress: "https://example.com")
    static let wporgCredentials = Credentials(username: "yayaya", password: "5678", siteAddress: "https://wordpress.com")
}
