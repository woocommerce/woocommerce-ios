import XCTest
import TestKit
import Yosemite
@testable import WooCommerce

class InPersonPaymentsMenuViewModelTests: XCTestCase {
    private var stores: MockStoresManager!

    private var sut: InPersonPaymentsMenuViewModel!

    private let sampleStoreID: Int64 = 12345

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.sessionManager.setStoreId(sampleStoreID)

        sut = InPersonPaymentsMenuViewModel(stores: stores)
    }

    func test_viewDidLoad_synchronizes_payment_gateways() throws {
        // Given
        assertEmpty(stores.receivedActions)

        // When
        sut.viewDidLoad()

        // Then
        let action = try XCTUnwrap(stores.receivedActions.last as? PaymentGatewayAction)
        switch action {
        case .synchronizePaymentGateways(let siteID, _):
            assertEqual(siteID, sampleStoreID)
        default:
            XCTFail("viewDidLoad failed to dispatch .synchronizePaymentGateways action")
        }
    }
}
