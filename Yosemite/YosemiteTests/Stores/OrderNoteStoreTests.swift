import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// OrderNoteStore Unit Tests
///
class OrderNoteStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID = 123

    /// Dummy Order ID
    ///
    private let sampleOrderID = 963


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    /// Verifies that OrderNoteAction.retrieveOrderNotes returns the expected OrderNotes.
    ///
    func testRetrieveOrderNotesReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve order notes")
        let orderNoteStore = OrderNoteStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteCustomerNote = sampleCustomerNote()
        let remoteSellerNote = sampleSellerNote()

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/notes/", filename: "order-notes")
        let action = OrderNoteAction.retrieveOrderNotes(siteID: sampleSiteID, orderID: sampleOrderID) { (orderNotes, error) in
            XCTAssertNil(error)
            guard let orderNotes = orderNotes else {
                XCTFail()
                return
            }
            XCTAssertEqual(orderNotes.count, 18)
            XCTAssertEqual(orderNotes[0], remoteCustomerNote)
            XCTAssertEqual(orderNotes[2], remoteSellerNote)
            expectation.fulfill()
        }

        orderNoteStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderNoteAction.retrieveOrderNotes returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveOrderNotesReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve order notes error response")
        let orderNoteStore = OrderNoteStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/notes/", filename: "generic_error")
        let action = OrderNoteAction.retrieveOrderNotes(siteID: sampleSiteID, orderID: sampleOrderID) { (orderNotes, error) in
            XCTAssertNil(orderNotes)
            XCTAssertNotNil(error)
            guard let _ = error else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }

        orderNoteStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderNoteAction.retrieveOrderNotes returns an error whenever there is no backend response.
    ///
    func testRetrieveOrderNotesReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve order notes empty response")
        let orderNoteStore = OrderNoteStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = OrderNoteAction.retrieveOrderNotes(siteID: sampleSiteID, orderID: sampleOrderID) { (orderNotes, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(orderNotes)
            guard let _ = error else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }

        orderNoteStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}

// MARK: - Private Methods
//
private extension OrderNoteStoreTests {
    func sampleCustomerNote() -> Networking.OrderNote {
        return OrderNote(noteId: 2261,
                         dateCreated: date(with: "2018-06-23T17:06:55"),
                         note: "I love your products!",
                         isCustomerNote: true)
    }

    func sampleSellerNote() -> Networking.OrderNote {
        return OrderNote(noteId: 2073,
                         dateCreated: date(with: "2018-05-26T05:00:24"),
                         note: "Order status changed from Processing to Completed.",
                         isCustomerNote: false)
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}

