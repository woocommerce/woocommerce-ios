import XCTest
@testable import WooCommerce
import Yosemite


/// SessionManager Unit Tests
///
class SessionManagerTests: XCTestCase {

    /// CredentialsStorage Unit-Testing Instance
    ///
    private var manager = SessionManager(defaults: .standard, keychainServiceName: Constants.testingServiceName)


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
        manager.credentials = Constants.testingCredentials1

        let retrieved = manager.credentials
        XCTAssertEqual(retrieved?.authToken, Constants.testingCredentials1.authToken)
        XCTAssertEqual(retrieved?.username, Constants.testingCredentials1.username)
    }

    /// Verifies that `removeDefaultCredentials` effectively nukes everything from the keychain
    ///
    func testDefaultCredentialsAreEffectivelyNuked() {
        manager.credentials = Constants.testingCredentials1
        manager.credentials = nil

        XCTAssertNil(manager.credentials)
    }

    /// Verifies that `saveDefaultCredentials` overrides previous stored credentials
    ///
    func testDefaultCredentialsCanBeUpdated() {
        manager.credentials = Constants.testingCredentials1
        XCTAssertEqual(manager.credentials, Constants.testingCredentials1)

        manager.credentials = Constants.testingCredentials2
        XCTAssertEqual(manager.credentials, Constants.testingCredentials2)
    }
}


// MARK: - Nested Types
//
private extension SessionManagerTests {

    struct Constants {
        static let testingServiceName = "com.automattic.woocommerce.tests"
        static let testingCredentials1 = Credentials(username: "lalala", authToken: "1234")
        static let testingCredentials2 = Credentials(username: "yayaya", authToken: "5678")
    }
}
