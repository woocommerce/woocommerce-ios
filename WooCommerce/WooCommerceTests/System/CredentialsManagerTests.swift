import XCTest
@testable import WooCommerce
import Yosemite


/// CredentialsManager Unit Tests
///
class CredentialsManagerTests: XCTestCase {

    /// CredentialsManager Unit-Testing Instance
    ///
    private let manager = CredentialsManager(serviceName: Constants.testingServiceName)


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        manager.removeDefaultCredentials()
    }


    /// Verifies that `loadDefaultCredentials` returns nil whenever there are no default credentials stored.
    ///
    func testLoadDefaultCredentialsReturnsNilWhenThereAreNoDefaultCredentials() {
        XCTAssertNil(manager.loadDefaultCredentials())
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func testDefaultCredentialsAreProperlyPersisted() {
        manager.saveDefaultCredentials(Constants.testingCredentials)

        let retrieved = manager.loadDefaultCredentials()
        XCTAssertEqual(retrieved?.authToken, Constants.testingCredentials.authToken)
        XCTAssertEqual(retrieved?.username, Constants.testingCredentials.username)
    }

    /// Verifies that `removeDefaultCredentials` effectively nukes everything from the keychain
    ///
    func testDefaultCredentialsAreEffectivelyNuked() {
        manager.saveDefaultCredentials(Constants.testingCredentials)
        manager.removeDefaultCredentials()

        let retrieved = manager.loadDefaultCredentials()
        XCTAssertNil(retrieved)
    }

    /// Verifies that `saveDefaultCredentials` overrides previous stored credentials
    ///
    func testDefaultCredentialsCanBeUpdated() {
        manager.saveDefaultCredentials(Constants.testingCredentials)

        let retrieved = manager.loadDefaultCredentials()
        XCTAssertEqual(retrieved, Constants.testingCredentials)

        let updated = Credentials(username: Constants.testingCredentials.username, authToken: "5678")
        manager.saveDefaultCredentials(updated)

        let reloaded = manager.loadDefaultCredentials()
        XCTAssertEqual(reloaded, updated)
    }
}


// MARK: - Nested Types
//
private extension CredentialsManagerTests {

    struct Constants {
        static let testingServiceName = "com.automattic.woocommerce.tests"
        static let testingCredentials = Credentials(username: "lalala", authToken: "1234")
    }
}
