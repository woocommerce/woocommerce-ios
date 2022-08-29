import XCTest
import Yosemite
@testable import WooCommerce

/// AddressValidator Unit Tests
///
class AddressValidatorTests: XCTestCase {
    private var storesManager: MockStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(storesManager)
    }

    func testExample() {
        var onCompletionWasCalled = false

        let addressValidator = AddressValidator(siteID: 123, stores: storesManager)

        addressValidator.validate(address: Address.empty, onlyLocally: true, onCompletion: { result in
            onCompletionWasCalled = true
            guard let failure = result.failure else {
                XCTFail("A failure result was expected for an empty address")
                return
            }

            switch failure {
            case .local(let errorMessage):
                XCTAssertTrue(errorMessage.isNotEmpty)
                break
            default:
                XCTFail("A local failure was expected")
            }
        })

        XCTAssertTrue(onCompletionWasCalled)
    }
}
