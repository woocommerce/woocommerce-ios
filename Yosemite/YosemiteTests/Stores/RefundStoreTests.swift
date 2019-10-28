import XCTest
@testable import Networking
@testable import Storage
@testable import Yosemite


/// RefundStore Unit Tests
///
class RefundStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID = 999

    /// Testing OrderID
    ///
    private let sampleOrderID = 560

    /// Testing Page Number
    ///
    private let defaultPageNumber = 1

    /// Testing Page Size
    ///
    private let defaultPageSize = 25


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    override func tearDown() {
        super.tearDown()
        // anything that needs cleared after each unit test, should be added here.
    }


    // MARK: - RefundAction.synchronizeRefunds

    /// Verifies that RefundAction.synchronizeRefunds effectively persists any retrieved refunds.
    ///
    func testRetrieveRefundsEffectivelyPersistsRetrievedRefunds() {
        let expectation = self.expectation(description: "Retrieve refunds")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "refunds", filename: "refunds-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 0)

        let action = RefundAction.synchronizeRefunds(siteID: sampleSiteID, orderID: sampleOrderID, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Refund.self), 2)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
