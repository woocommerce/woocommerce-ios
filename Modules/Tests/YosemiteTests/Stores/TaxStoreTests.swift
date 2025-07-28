import XCTest
import Fakes
@testable import Yosemite
@testable import Networking
@testable import Storage


/// TaxStore Unit Tests
///
final class TaxStoreTests: XCTestCase {

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
    private var store: TaxStore!

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
        store = TaxStore(dispatcher: dispatcher,
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


    // MARK: - TaxAction.retrieveTaxClasses

    /// Verifies that `TaxAction.retrieveTaxClasses` effectively persists any retrieved tax class.
    ///
    func testRetrieveTaxClassesEffectivelyPersistsRetrievedTaxClasses() {
        let expectation = self.expectation(description: "Retrieve tax class list")

        network.simulateResponse(requestUrlSuffix: "taxes/classes", filename: "taxes-classes")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TaxClass.self), 0)

        let action = TaxAction.retrieveTaxClasses(siteID: sampleSiteID) { (taxClasses, error) in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.TaxClass.self), 3)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `TaxAction.retrieveTaxClasses` effectively persists all of the fields
    /// correctly across all of the related `TaxClass` entities
    ///
    func testRetrieveTaxClassesEffectivelyPersistsTaxClassFields() {
        let expectation = self.expectation(description: "Persist tax class list")

        let remoteTaxClass = sampleTaxClass()

        network.simulateResponse(requestUrlSuffix: "taxes/classes", filename: "taxes-classes")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TaxClass.self), 0)

        let action = TaxAction.retrieveTaxClasses(siteID: sampleSiteID) { (taxClasses, error) in
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

    /// Verifies that `TaxAction.retrieveTaxClasses` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveTaxClassesReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve tax class error response")

        network.simulateResponse(requestUrlSuffix: "taxes/classes", filename: "generic_error")

        let action = TaxAction.retrieveTaxClasses(siteID: sampleSiteID) { (taxClasses, error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `TaxAction.retrieveTaxClasses` returns an error whenever there is no backend response.
    ///
    func testRetrieveTaxClassesReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve tax class empty response")

        let action = TaxAction.retrieveTaxClasses(siteID: sampleSiteID) { (taxClasses, error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `TaxAction.retrieveTaxClasses` returns the expected `TaxClass`.
    ///
    func testRetrieveTaxClassesReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve single tax class")
        let remoteTaxClass = sampleTaxClass()

        network.simulateResponse(requestUrlSuffix: "taxes/classes", filename: "taxes-classes")
        let action = TaxAction.retrieveTaxClasses(siteID: sampleSiteID) { (taxClasses, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(taxClasses?.first)
            XCTAssertEqual(taxClasses?.first, remoteTaxClass)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - TaxAction.requestMissingTaxClasses

    /// Verifies that `TaxAction.requestMissingTaxClasses` request the Tax Class found in a specified Product.
    ///
    func testRequestMissingTaxClassesEffectivelyReturnMissingTaxClass() {
        let expectation = self.expectation(description: "Return missing tax class")

        let product = Product.fake().copy(siteID: sampleSiteID, productID: 2020, taxClass: "standard")
        network.simulateResponse(requestUrlSuffix: "taxes/classes", filename: "taxes-classes")
        let action = TaxAction.requestMissingTaxClasses(for: product) { (taxClass, error) in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.TaxClass.self), 3)

            XCTAssertEqual(taxClass?.slug, product.taxClass)
            XCTAssertEqual(taxClass?.name, "Standard Rate")

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - TaxAction.upsertStoredTaxClass

    /// Verifies that `TaxAction.upsertStoredTaxClass` does not produce duplicate entries.
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

    func test_retrieveTaxRates_then_persists_TaxRates() {
        network.simulateResponse(requestUrlSuffix: "taxes", filename: "taxes")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TaxRate.self), 0)

        // When
        let result: Result<[Yosemite.TaxRate], Error> = waitFor { [weak self] promise in
            guard let self = self else { return }

            let action = TaxAction.retrieveTaxRates(siteID: self.sampleSiteID, pageNumber: 1, pageSize: 25) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TaxRate.self), 3)
    }

    func test_retrieveTaxRate_then_persists_TaxRate() {
        let taxRateID: Int64 = 1
        network.simulateResponse(requestUrlSuffix: "taxes/\(taxRateID)", filename: "tax")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TaxRate.self), 0)

        // When
        let result: Result<Yosemite.TaxRate, Error> = waitFor { [weak self] promise in
            guard let self = self else { return }

            let action = TaxAction.retrieveTaxRate(siteID: self.sampleSiteID, taxRateID: taxRateID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.TaxRate.self), 1)
    }
}


// MARK: - Private Helpers
//
private extension TaxStoreTests {

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
