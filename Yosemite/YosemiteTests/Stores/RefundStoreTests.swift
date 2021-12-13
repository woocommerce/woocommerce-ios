import XCTest
@testable import Networking
@testable import Storage
@testable import Yosemite


/// RefundStore Unit Tests
///
class RefundStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 999

    /// Testing SitID #2
    ///
    private let sampleSiteID2: Int64 = 187634

    /// Testing OrderID
    ///
    private let sampleOrderID: Int64 = 560

    /// Testing RefundID
    ///
    private let sampleRefundID: Int64 = 590

    /// RefundID for a single refund
    ///
    private let refundID: Int64 = 562

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
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    override func tearDown() {
        super.tearDown()
        // anything that needs cleared after each unit test, should be added here.
    }


    // MARK: - RefundAction.synchronizeRefunds

    /// Verifies that `RefundAction.synchronizeRefunds` effectively persists any retrieved refunds.
    ///
    func testRetrieveRefundsEffectivelyPersistsRetrievedRefunds() {
        let expectation = self.expectation(description: "Retrieve refunds")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "refunds", filename: "refunds-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 0)

        let action = RefundAction.synchronizeRefunds(siteID: sampleSiteID,
                                                     orderID: sampleOrderID,
                                                     pageNumber: defaultPageNumber,
                                                     pageSize: defaultPageSize) { error in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Refund.self), 2)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `RefundAction.synchronizeRefunds` effectively persists all of the refund fields
    /// correctly across the related `Refund` entities (OrderItemRefund, for example).
    ///
    func testRetrieveRefundsEffectivelyPersistsRefundFieldsAndRelatedObjects() {
        let expectation = self.expectation(description: "Persist refunds list")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteRefund = sampleRefund()

        network.simulateResponse(requestUrlSuffix: "refunds", filename: "refunds-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 0)

        let action = RefundAction.synchronizeRefunds(siteID: sampleSiteID,
                                                     orderID: sampleOrderID,
                                                     pageNumber: defaultPageNumber,
                                                     pageSize: defaultPageSize) { error in
            XCTAssertNil(error)

            let storedRefund = self.viewStorage.loadRefund(siteID: self.sampleSiteID,
                                                           orderID: self.sampleOrderID,
                                                           refundID: self.sampleRefundID)
            let readOnlyStoredRefund = storedRefund?.toReadOnly()
            XCTAssertNotNil(storedRefund)
            XCTAssertNotNil(readOnlyStoredRefund)
            XCTAssertEqual(readOnlyStoredRefund, remoteRefund)

            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `RefundAction.synchronizeRefunds` returns an error
    /// whenever there is an error response from the backend.
    ///
    func testRetrieveRefundsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve refunds error response")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "refunds", filename: "generic_error")
        let action = RefundAction.synchronizeRefunds(siteID: sampleSiteID,
                                                     orderID: sampleOrderID,
                                                     pageNumber: defaultPageNumber,
                                                     pageSize: defaultPageSize) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `RefundAction.synchronizeRefunds` returns an error whenever there is no backend response.
    ///
    func testRetrieveProductsReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve refunds empty response")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = RefundAction.synchronizeRefunds(siteID: sampleSiteID,
                                                     orderID: sampleOrderID,
                                                     pageNumber: defaultPageNumber,
                                                     pageSize: defaultPageSize) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - RefundAction.retrieveRefund

    /// Verifies that `RefundAction.retrieveRefund` returns the expected `Refund`.
    ///
    func testRetrieveSingleRefundReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve single refund")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteRefund = sampleRefund2()

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/refunds/\(refundID)", filename: "refund-single")
        let action = RefundAction.retrieveRefund(siteID: sampleSiteID,
                                                 orderID: sampleOrderID,
                                                 refundID: refundID) { (refund, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(refund)
            XCTAssertEqual(refund, remoteRefund)

            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `RefundAction.retrieveRefund` effectively persists all of the remote product fields
    /// correctly across all of the related `Refund` entities (such as OrderItemRefund).
    ///
    func testRetrieveSingleRefundEffectivelyPersistsRefundFieldsAndRelatedObjects() {
        let expectation = self.expectation(description: "Persist single refund")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteRefund = sampleRefund2()

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/refunds/\(refundID)", filename: "refund-single")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 0)

        let action = RefundAction.retrieveRefund(siteID: sampleSiteID,
                                                 orderID: sampleOrderID,
                                                 refundID: refundID) { (refund, error) in
            XCTAssertNotNil(refund)
            XCTAssertNil(error)

            let storedRefund = self.viewStorage.loadRefund(siteID: self.sampleSiteID,
                                                           orderID: self.sampleOrderID,
                                                           refundID: self.refundID)
            let readOnlyStoredRefund = storedRefund?.toReadOnly()
            XCTAssertNotNil(storedRefund)
            XCTAssertNotNil(readOnlyStoredRefund)
            XCTAssertEqual(readOnlyStoredRefund, remoteRefund)

            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `RefundAction.retrieveRefund` returns an error
    /// whenever there is an error response from the backend.
    ///
    func testRetrieveSingleRefundReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve a single refund's error response")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/refunds/\(refundID)", filename: "generic_error")
        let action = RefundAction.retrieveRefund(siteID: sampleSiteID,
                                                 orderID: sampleOrderID,
                                                 refundID: refundID) { (refund, error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `RefundAction.retrieveRefund` returns an error whenever there is no backend response.
    ///
    func testRetrieveSingleRefundReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve a single refund's empty response")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = RefundAction.retrieveRefund(siteID: sampleSiteID,
                                                 orderID: sampleOrderID,
                                                 refundID: refundID) { (refund, error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that whenever a `RefundAction.retrieveRefund`
    /// action results in a response with statusCode = 404
    /// and the local entity is obliterated from existence.
    ///
    func testRetrieveSingleRefundResultingInStatusCode404CausesTheStoredRefundToGetDeleted() {
        let expectation = self.expectation(description: "Delete single refund when response is 404 not found")
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 0)
        refundStore.upsertStoredRefund(readOnlyRefund: sampleRefund(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 1)

        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/refunds/\(sampleRefundID)", error: NetworkError.notFound)
        let action = RefundAction.retrieveRefund(siteID: sampleSiteID,
                                                 orderID: sampleOrderID,
                                                 refundID: sampleRefundID) { (refund, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(refund)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Refund.self), 0)

            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - RefundAction.resetStoredRefunds

    /// Verifies that `RefundAction.resetStoredRefunds` deletes the Refunds from Storage
    ///
    func testResetStoredRefundsEffectivelyNukesTheRefundsCache() {
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let expectation = self.expectation(description: "Reset stored refunds")
        let action = RefundAction.resetStoredRefunds() {
            refundStore.upsertStoredRefund(readOnlyRefund: self.sampleRefund(), in: self.viewStorage)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Refund.self), 1)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderItemRefund.self), 1)

            expectation.fulfill()
        }

        refundStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - RefundStore.upsertStoredRefund

    /// Verifies that `RefundStore.upsertStoredRefund` does not produce duplicate entries.
    ///
    func testUpdateStoredRefundEffectivelyUpdatesPreexistantRefund() {
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Refund.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderItemRefund.self), 0)

        refundStore.upsertStoredRefund(readOnlyRefund: sampleRefund(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemRefund.self), 1)

        refundStore.upsertStoredRefund(readOnlyRefund: sampleRefundMutated(), in: viewStorage)
        let storageRefund1 = viewStorage.loadRefund(siteID: sampleSiteID, orderID: sampleOrderID, refundID: sampleRefundID)
        XCTAssertEqual(storageRefund1?.toReadOnly(), sampleRefundMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemRefund.self), 2)
    }

    /// Verifies that `RefundStore.upsertStoredRefund` updates the correct site's refund.
    ///
    func testUpdateStoredRefundEffectivelyUpdatesCorrectSitesRefund() {
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Refund.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderItemRefund.self), 0)

        refundStore.upsertStoredRefund(readOnlyRefund: sampleRefund(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemRefund.self), 1)

        refundStore.upsertStoredRefund(readOnlyRefund: sampleRefund(sampleSiteID2), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemRefund.self), 2)

        refundStore.upsertStoredRefund(readOnlyRefund: sampleRefundMutated(), in: viewStorage)
        let storageRefund1 = viewStorage.loadRefund(siteID: sampleSiteID, orderID: sampleOrderID, refundID: sampleRefundID)
        XCTAssertEqual(storageRefund1?.toReadOnly(), sampleRefundMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemRefund.self), 3)

        let storageRefund2 = viewStorage.loadRefund(siteID: sampleSiteID2, orderID: sampleOrderID, refundID: sampleRefundID)
        XCTAssertEqual(storageRefund2?.toReadOnly(), sampleRefund(sampleSiteID2))
    }

    /// Verifies that `RefundStore.upsertStoredRefund` effectively inserts a new Refund, with the specified payload.
    ///
    func testUpdateStoredRefundEffectivelyPersistsNewRefund() {
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteRefund = sampleRefund()

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Refund.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderItemRefund.self), 0)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderItemTaxRefund.self), 0)
        refundStore.upsertStoredRefund(readOnlyRefund: remoteRefund, in: viewStorage)

        let storageRefund = viewStorage.loadRefund(siteID: sampleSiteID, orderID: sampleOrderID, refundID: sampleRefundID)
        XCTAssertEqual(storageRefund?.toReadOnly(), remoteRefund)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemRefund.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemTaxRefund.self), 0)
    }

    /// Verifies that Innocuous Upsert Operations (OPs) performed in Derived Contexts **DO NOT** trigger Refresh Events in the
    /// main thread.
    ///
    /// This translates effectively into: Ensure that performing update OPs that don't really change anything, do not
    /// end up causing UI refresh OPs in the main thread.
    ///
    func testInnocuousRefundUpdateOperationsPerformedInBackgroundDoNotTriggerUpsertEventsInTheMainThread() {
        // Stack
        let viewContext = storageManager.persistentContainer.viewContext
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let entityListener = EntityListener(viewContext: viewContext, readOnlyEntity: sampleRefund())

        // Track Events: Upsert == 1 / Delete == 0
        var numberOfUpsertEvents = 0
        entityListener.onUpsert = { upserted in
            numberOfUpsertEvents += 1
        }

        // We expect *never* to get a deletion event
        entityListener.onDelete = {
            XCTFail()
        }

        // Initial save: This should trigger *ONE* Upsert event
        let backgroundSaveExpectation = expectation(description: "Retrieve empty response for a refund")
        let derivedContext = storageManager.writerDerivedStorage

        derivedContext.perform {
            refundStore.upsertStoredRefund(readOnlyRefund: self.sampleRefund(), in: derivedContext)
        }

        storageManager.saveDerivedType(derivedStorage: derivedContext) {

            // Secondary Save: Expect ZERO new Upsert Events
            derivedContext.perform {
                refundStore.upsertStoredRefund(readOnlyRefund: self.sampleRefund(), in: derivedContext)
            }

            self.storageManager.saveDerivedType(derivedStorage: derivedContext) {
                XCTAssertEqual(numberOfUpsertEvents, 1)
                backgroundSaveExpectation.fulfill()
            }
        }

        wait(for: [backgroundSaveExpectation], timeout: Constants.expectationTimeout)
    }

    func test_stale_refunds_are_deleted_when_retrieving_new_refunds_with_deleteStaleRefunds_flag() {
        // Given
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        refundStore.upsertStoredRefund(readOnlyRefund: sampleRefund(refundID: 999), in: viewStorage)
        network.simulateResponse(requestUrlSuffix: "refunds", filename: "refunds-all")

        // When
        var retrieveError: Error?
        waitForExpectation { exp in
            let action = RefundAction.retrieveRefunds(siteID: sampleSiteID,
                                                      orderID: sampleOrderID,
                                                      refundIDs: [sampleRefundID, refundID],
                                                      deleteStaleRefunds: true) { error in
                retrieveError = error
                exp.fulfill()
            }
            refundStore.onAction(action)
        }

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 2)
        XCTAssertNil(retrieveError)
    }

    func test_stale_refunds_are_not_deleted_when_retrieving_new_refunds_without_deleteStaleRefunds_flag() {
        // Given
        let refundStore = RefundStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        refundStore.upsertStoredRefund(readOnlyRefund: sampleRefund(refundID: 999), in: viewStorage)
        network.simulateResponse(requestUrlSuffix: "refunds", filename: "refunds-all")

        // When
        var retrieveError: Error?
        waitForExpectation { exp in
            let action = RefundAction.retrieveRefunds(siteID: sampleSiteID,
                                                      orderID: sampleOrderID,
                                                      refundIDs: [sampleRefundID, refundID],
                                                      deleteStaleRefunds: false) { error in
                retrieveError = error
                exp.fulfill()
            }
            refundStore.onAction(action)
        }

        // Then
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Refund.self), 3)
        XCTAssertNil(retrieveError)
    }
}


// MARK: - Private Helpers
//
private extension RefundStoreTests {

    /// Generate a sample Refund
    ///
    func sampleRefund(_ siteID: Int64? = nil, refundID: Int64? = nil) -> Networking.Refund {
        let testSiteID = siteID ?? sampleSiteID
        let testDate = date(with: "2019-10-09T16:18:23")
        return Refund(refundID: refundID ?? sampleRefundID,
                      orderID: sampleOrderID,
                      siteID: testSiteID,
                      dateCreated: testDate,
                      amount: "18.00",
                      reason: "Only 1 black hoodie left. Inventory count was off. My bad!",
                      refundedByUserID: 1,
                      isAutomated: true,
                      createAutomated: false,
                      items: [sampleOrderItem()],
                      shippingLines: nil)
    }

    /// Generate a mutated Refund
    ///
    func sampleRefundMutated(_ siteID: Int64? = nil) -> Networking.Refund {
        let testSiteID = siteID ?? sampleSiteID
        let testDate = date(with: "2019-10-09T16:18:23")
        return Refund(refundID: sampleRefundID,
                      orderID: sampleOrderID,
                      siteID: testSiteID,
                      dateCreated: testDate,
                      amount: "18.00",
                      reason: "Only 1 black hoodie left. Inventory count was off. My bad!",
                      refundedByUserID: 3,
                      isAutomated: true,
                      createAutomated: false,
                      items: [sampleOrderItem(), sampleOrderItem2()],
                      shippingLines: [])
    }

    /// Generate a single Refund
    ///
    func sampleRefund2(_ siteID: Int64? = nil) -> Networking.Refund {
        let testSiteID = siteID ?? sampleSiteID
        let testDate = date(with: "2019-10-01T19:33:46")
        return Refund(refundID: refundID,
                      orderID: sampleOrderID,
                      siteID: testSiteID,
                      dateCreated: testDate,
                      amount: "27.00",
                      reason: "My pet hamster ate the sleeve off of one of the Blue XL hoodies. Sorry! No longer for sale.",
                      refundedByUserID: 1,
                      isAutomated: true,
                      createAutomated: false,
                      items: [sampleOrderItem2()],
                      shippingLines: [sampleShippingLine()])
    }

    /// Returns an `Order` with empty values. Use `copy()` to modify them.
    func sampleOrder() -> Networking.Order {
        Order(
            siteID: sampleSiteID,
            orderID: sampleOrderID,
            parentID: 0,
            customerID: 0,
            number: "",
            status: .pending,
            currency: "",
            customerNote: nil,
            dateCreated: Date(),
            dateModified: Date(),
            datePaid: nil,
            discountTotal: "",
            discountTax: "",
            shippingTotal: "",
            shippingTax: "",
            total: "",
            totalTax: "",
            paymentMethodID: "",
            paymentMethodTitle: "",
            items: [],
            billingAddress: nil,
            shippingAddress: nil,
            shippingLines: [],
            coupons: [],
            refunds: [],
            fees: []
        )
    }

    /// Generate a sample OrderItem
    ///
    func sampleOrderItem() -> Networking.OrderItemRefund {
        return OrderItemRefund(itemID: 73,
                               name: "Ninja Silhouette",
                               productID: 22,
                               variationID: 0,
                               quantity: -1,
                               price: 18,
                               sku: "T-SHIRT-NINJA-SILHOUETTE",
                               subtotal: "-18.00",
                               subtotalTax: "0.00",
                               taxClass: "",
                               taxes: [],
                               total: "-18.00",
                               totalTax: "0.00")
    }

    /// Generate another sample OrderItem
    ///
    func sampleOrderItem2() -> Networking.OrderItemRefund {
        return OrderItemRefund(itemID: 67,
                               name: "Ship Your Idea - Blue, XL",
                               productID: 21,
                               variationID: 70,
                               quantity: -1,
                               price: 27,
                               sku: "HOODIE-SHIP-YOUR-IDEA-BLUE-XL",
                               subtotal: "-27.00",
                               subtotalTax: "0.00",
                               taxClass: "",
                               taxes: [],
                               total: "-27.00",
                               totalTax: "0.00")
    }

    func sampleShippingLine() -> Networking.ShippingLine {
        ShippingLine(shippingID: 189,
                     methodTitle: "Flat rate",
                     methodID: "flat_rate",
                     total: "-7.00",
                     totalTax: "-0.62",
                     taxes: [.init(taxID: 1, subtotal: "", total: "-0.62")])
    }

    /// Format GMT string to Date type
    ///
    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
