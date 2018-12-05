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

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

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

    /// Verifies that `OrderNoteAction.retrieveOrderNotes` effectively persists any retrieved order notes.
    ///
    func testRetrieveOrderNotesEffectivelyPersistsRetrievedOrderNotes() {
        let expectation = self.expectation(description: "Persist order note list")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let orderNoteStore = OrderNoteStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrder(), in: viewStorage)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/notes/", filename: "order-notes")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderNote.self), 0)
        let action = OrderNoteAction.retrieveOrderNotes(siteID: sampleSiteID, orderID: sampleOrderID) { (orderNotes, error) in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderNote.self), 18)
            XCTAssertNotNil(orderNotes)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        orderNoteStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `OrderNoteAction.retrieveOrderNotes` effectively persists all of the order note fields.
    ///
    func testRetrieveOrderNotesEffectivelyPersistsOrderNoteFields() {
        let expectation = self.expectation(description: "Persist order note list")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let orderNoteStore = OrderNoteStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteCustomerNote = sampleCustomerNote()
        let remoteSellerNote = sampleSellerNote()

        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrder(), in: viewStorage)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/notes/", filename: "order-notes")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderNote.self), 0)
        let action = OrderNoteAction.retrieveOrderNotes(siteID: sampleSiteID, orderID: sampleOrderID) { (orderNotes, error) in
            XCTAssertNotNil(orderNotes)
            XCTAssertNil(error)

            let customerPredicate = NSPredicate(format: "noteID = %ld", remoteCustomerNote.noteID)
            let storedCustomerNote = self.viewStorage.firstObject(ofType: Storage.OrderNote.self, matching: customerPredicate)
            let readOnlyStoredCustomerNote = storedCustomerNote?.toReadOnly()
            XCTAssertNotNil(storedCustomerNote)
            XCTAssertNotNil(readOnlyStoredCustomerNote)
            XCTAssertEqual(readOnlyStoredCustomerNote, remoteCustomerNote)

            let sellerPredicate = NSPredicate(format: "noteID = %ld", remoteSellerNote.noteID)
            let storedSellerNote = self.viewStorage.firstObject(ofType: Storage.OrderNote.self, matching: sellerPredicate)
            let readOnlyStoredSellerNote = storedSellerNote?.toReadOnly()
            XCTAssertNotNil(storedSellerNote)
            XCTAssertNotNil(readOnlyStoredSellerNote)
            XCTAssertEqual(readOnlyStoredSellerNote, remoteSellerNote)

            expectation.fulfill()
        }

        orderNoteStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertStoredOrderNote` does not produce duplicate entries.
    ///
    func testUpdateStoredOrderNoteEffectivelyUpdatesPreexistantOrderNote() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let orderNoteStore = OrderNoteStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrder(), in: viewStorage)

        XCTAssertNil(viewStorage.firstObject(ofType: Storage.OrderNote.self, matching: nil))
        orderNoteStore.upsertStoredOrderNote(readOnlyOrderNote: sampleCustomerNote(), orderID: sampleOrderID)
        orderNoteStore.upsertStoredOrderNote(readOnlyOrderNote: sampleCustomerNoteMutated(), orderID: sampleOrderID)
        XCTAssert(viewStorage.countObjects(ofType: Storage.OrderNote.self, matching: nil) == 1)

        let expectedNote = sampleCustomerNoteMutated()
        let storageOrderNote = viewStorage.loadOrderNote(noteID: expectedNote.noteID)
        XCTAssertEqual(storageOrderNote?.toReadOnly(), expectedNote)
    }

    /// Verifies that `upsertStoredOrderNote` effectively inserts a new OrderNote, with the specified payload.
    ///
    func testUpdateStoredOrderNoteEffectivelyPersistsNewOrderNote() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let orderNoteStore = OrderNoteStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrder(), in: viewStorage)
        let remoteOrderNote = sampleCustomerNote()

        XCTAssertNil(viewStorage.loadAccount(userId: remoteOrderNote.noteID))
        orderNoteStore.upsertStoredOrderNote(readOnlyOrderNote: remoteOrderNote, orderID: sampleOrderID)

        let storageOrderNote = viewStorage.loadOrderNote(noteID: remoteOrderNote.noteID)
        XCTAssertEqual(storageOrderNote?.toReadOnly(), remoteOrderNote)
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

    func sampleCustomerNoteMutated() -> Networking.OrderNote {
        return OrderNote(noteId: 2261,
                         dateCreated: date(with: "2018-06-23T17:06:55"),
                         note: "I HATE your products!",
                         isCustomerNote: false)
    }

    func sampleSellerNote() -> Networking.OrderNote {
        return OrderNote(noteId: 2073,
                         dateCreated: date(with: "2018-05-26T05:00:24"),
                         note: "Order status changed from Processing to Completed.",
                         isCustomerNote: false)
    }

    func sampleOrder() -> Networking.Order {
        return Order(siteID: sampleSiteID,
                     orderID: sampleOrderID,
                     parentID: 0,
                     customerID: 11,
                     number: "963",
                     status: .processing,
                     currency: "USD",
                     customerNote: "",
                     dateCreated: date(with: "2018-04-03T23:05:12"),
                     dateModified: date(with: "2018-04-03T23:05:14"),
                     datePaid: date(with: "2018-04-03T23:05:14"),
                     discountTotal: "30.00",
                     discountTax: "1.20",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "31.20",
                     totalTax: "1.20",
                     paymentMethodTitle: "Credit Card (Stripe)",
                     items: [],
                     billingAddress: sampleAddress(),
                     shippingAddress: sampleAddress(),
                     coupons: [])
    }

    func sampleAddress() -> Networking.Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: "",
                       address1: "234 70th Street",
                       address2: "",
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "333-333-3333",
                       email: "scrambled@scrambled.com")
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}

