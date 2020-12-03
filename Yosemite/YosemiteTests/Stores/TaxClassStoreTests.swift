import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// TaxClassStore Unit Tests
///
final class TaxClassStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Store
    ///
    private var store: TaxClassStore!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        store = TaxClassStore(dispatcher: dispatcher,
                                storageManager: storageManager,
                                network: network)
    }

    override func tearDown() {
        store = nil
        dispatcher = nil
        storageManager = nil
        network = nil

        super.tearDown()
    }


    // MARK: - TaxClassAction.retrieveTaxClasses

    /// Verifies that `TaxClassAction.retrieveTaxClasses` effectively persists any retrieved tax class.
    ///
    func testRetrieveTaxClassesEffectivelyPersistsRetrievedTaxClasses() {
        let expectation = self.expectation(description: "Retrieve tax class list")

        network.simulateResponse(requestUrlSuffix: "taxes/classes", filename: "taxes-classes")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TaxClass.self), 0)

        let action = TaxClassAction.retrieveTaxClasses(siteID: sampleSiteID) { (taxClasses, error) in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.TaxClass.self), 3)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `TaxClassAction.retrieveTaxClasses` effectively persists all of the fields
    /// correctly across all of the related `TaxClass` entities
    ///
    func testRetrieveTaxClassesEffectivelyPersistsTaxClassFields() {
        let expectation = self.expectation(description: "Persist tax class list")

        let remoteTaxClass = sampleTaxClass()

        network.simulateResponse(requestUrlSuffix: "taxes/classes", filename: "taxes-classes")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TaxClass.self), 0)

        let action = TaxClassAction.retrieveTaxClasses(siteID: sampleSiteID) { (taxClasses, error) in
            XCTAssertNil(error)

            let storedTaxClass = self.viewStorage.loadTaxClass(slug: remoteTaxClass.slug)
            let readOnlyStoredTaxClass = storedTaxClass?.toReadOnly()
            XCTAssertNotNil(storedTaxClass)
            XCTAssertNotNil(readOnlyStoredTaxClass)
            XCTAssertEqual(readOnlyStoredTaxClass, remoteTaxClass)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `TaxClassAction.retrieveTaxClasses` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveTaxClassesReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve tax class error response")

        network.simulateResponse(requestUrlSuffix: "taxes/classes", filename: "generic_error")

        let action = TaxClassAction.retrieveTaxClasses(siteID: sampleSiteID) { (taxClasses, error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `TaxClassAction.retrieveTaxClasses` returns an error whenever there is no backend response.
    ///
    func testRetrieveTaxClassesReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve tax class empty response")

        let action = TaxClassAction.retrieveTaxClasses(siteID: sampleSiteID) { (taxClasses, error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `TaxClassAction.retrieveTaxClasses` returns the expected `TaxClass`.
    ///
    func testRetrieveTaxClassesReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve single tax class")
        let remoteTaxClass = sampleTaxClass()

        network.simulateResponse(requestUrlSuffix: "taxes/classes", filename: "taxes-classes")
        let action = TaxClassAction.retrieveTaxClasses(siteID: sampleSiteID) { (taxClasses, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(taxClasses?.first)
            XCTAssertEqual(taxClasses?.first, remoteTaxClass)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - TaxClassAction.requestMissingTaxClasses

    /// Verifies that `TaxClassAction.requestMissingTaxClasses` request the Tax Class found in a specified Product.
    ///
    func testRequestMissingTaxClassesEffectivelyReturnMissingTaxClass() {
        let expectation = self.expectation(description: "Return missing tax class")

        let product = MockProduct().product()
        network.simulateResponse(requestUrlSuffix: "taxes/classes", filename: "taxes-classes")
        let action = TaxClassAction.requestMissingTaxClasses(for: product) { (taxClass, error) in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.TaxClass.self), 3)

            XCTAssertEqual(taxClass?.slug, product.taxClass)
            XCTAssertEqual(taxClass?.name, "Standard Rate")

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - TaxClassAction.upsertStoredTaxClass

    /// Verifies that `TaxClassAction.upsertStoredTaxClass` does not produce duplicate entries.
    ///
    func testUpdateStoredTaxClassesEffectivelyUpdatesPreexistantTaxClass() {

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TaxClass.self), 0)
        store.upsertStoredTaxClass(readOnlyTaxClass: sampleTaxClass(), in: self.viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TaxClass.self), 1)

        store.upsertStoredTaxClass(readOnlyTaxClass: sampleTaxClassMutated(), in: self.viewStorage)
        let taxClass1 = viewStorage.loadTaxClass(slug: "standard")
        XCTAssertEqual(taxClass1?.toReadOnly(), sampleTaxClassMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TaxClass.self), 1)
    }
}


// MARK: - Private Helpers
//
private extension TaxClassStoreTests {

    func sampleTaxClass() -> Networking.TaxClass {
        return Networking.TaxClass(siteID: sampleSiteID,
                                   name: "Standard Rate",
                                   slug: "standard")
    }

    func sampleTaxClassMutated() -> Networking.TaxClass {
        return Networking.TaxClass(siteID: sampleSiteID,
                                   name: "Standard Rate Mutated",
                                   slug: "standard")
    }
}
