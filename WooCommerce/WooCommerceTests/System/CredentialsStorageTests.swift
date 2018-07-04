import XCTest
@testable import WooCommerce
import Yosemite


/// CredentialsStorage Unit Tests
///
class CredentialsStorageTests: XCTestCase {

    /// CredentialsStorage Unit-Testing Instance
    ///
    private let manager = CredentialsStorage(keychainServiceName: Constants.testingServiceName, defaults: .standard)


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        manager.removeCredentials()
    }


    /// Verifies that `loadDefaultCredentials` returns nil whenever there are no default credentials stored.
    ///
    func testLoadDefaultCredentialsReturnsNilWhenThereAreNoDefaultCredentials() {
        XCTAssertNil(manager.loadCredentials())
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func testDefaultCredentialsAreProperlyPersisted() {
        manager.saveCredentials(Constants.testingCredentials1)

        let retrieved = manager.loadCredentials()
        XCTAssertEqual(retrieved?.authToken, Constants.testingCredentials1.authToken)
        XCTAssertEqual(retrieved?.username, Constants.testingCredentials1.username)
    }

    /// Verifies that `removeDefaultCredentials` effectively nukes everything from the keychain
    ///
    func testDefaultCredentialsAreEffectivelyNuked() {
        manager.saveCredentials(Constants.testingCredentials1)
        manager.removeCredentials()

        XCTAssertNil(manager.loadCredentials())
    }

    /// Verifies that `saveDefaultCredentials` overrides previous stored credentials
    ///
    func testDefaultCredentialsCanBeUpdated() {
        manager.saveCredentials(Constants.testingCredentials1)
        XCTAssertEqual(manager.loadCredentials(), Constants.testingCredentials1)

        manager.saveCredentials(Constants.testingCredentials2)
        XCTAssertEqual(manager.loadCredentials(), Constants.testingCredentials2)
    }
}


// MARK: - Nested Types
//
private extension CredentialsStorageTests {

    struct Constants {
        static let testingServiceName = "com.automattic.woocommerce.tests"
        static let testingCredentials1 = Credentials(username: "lalala", authToken: "1234")
        static let testingCredentials2 = Credentials(username: "yayaya", authToken: "5678")
    }
}
