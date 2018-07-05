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
        manager.credentials = nil
    }


    /// Verifies that `loadDefaultCredentials` returns nil whenever there are no default credentials stored.
    ///
    func testLoadDefaultCredentialsReturnsNilWhenThereAreNoDefaultCredentials() {
        XCTAssertNil(manager.credentials)
    }


    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func testDefaultCredentialsAreProperlyPersisted() {
        manager.credentials = Settings.credentials1

        let retrieved = manager.credentials
        XCTAssertEqual(retrieved?.authToken, Settings.credentials1.authToken)
        XCTAssertEqual(retrieved?.username, Settings.credentials1.username)
    }


    /// Verifies that `removeDefaultCredentials` effectively nukes everything from the keychain
    ///
    func testDefaultCredentialsAreEffectivelyNuked() {
        manager.credentials = Settings.credentials1
        manager.credentials = nil

        XCTAssertNil(manager.credentials)
    }


    /// Verifies that `saveDefaultCredentials` overrides previous stored credentials
    ///
    func testDefaultCredentialsCanBeUpdated() {
        manager.credentials = Settings.credentials1
        XCTAssertEqual(manager.credentials, Settings.credentials1)

        manager.credentials = Settings.credentials2
        XCTAssertEqual(manager.credentials, Settings.credentials2)
    }
}


// MARK: - Testing Constants
//
private enum Settings {
    static let keychainServiceName = "com.automattic.woocommerce.tests"
    static let defaults = UserDefaults(suiteName: "sessionManagerTests")!
    static let credentials1 = Credentials(username: "lalala", authToken: "1234")
    static let credentials2 = Credentials(username: "yayaya", authToken: "5678")
}
