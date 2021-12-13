import XCTest
@testable import Yosemite
@testable import Storage
@testable import Networking


/// ProductTagStore Unit Tests
///
final class ProductTagStoreTests: XCTestCase {
    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Convenience Property: Returns stored product tags count.
    ///
    private var storedProductTagsCount: Int {
        return viewStorage.countObjects(ofType: Storage.ProductTag.self)
    }

    /// Store
    ///
    private var store: ProductTagStore!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing Page Number
    ///
    private let defaultPageNumber = 1

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        network = MockNetwork(useResponseQueue: true)
        storageManager = MockStorageManager()
        store = ProductTagStore(dispatcher: Dispatcher(),
                                     storageManager: storageManager,
                                     network: network)
    }

    override func tearDown() {
        store = nil
        network = nil
        storageManager = nil

        super.tearDown()
    }

    func testSynchronizeProductTagsReturnsTagsUponSuccessfulResponse() throws {
        // Given a stubed product-tags network response
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-all")
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-empty")
        XCTAssertEqual(storedProductTagsCount, 0)

        // When dispatching a `synchronizeAllProductTags` action
        var errorResponse: ProductTagActionError?
        waitForExpectation { (exp) in
            let action = ProductTagAction.synchronizeAllProductTags(siteID: sampleSiteID) { error in
                errorResponse = error
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then a valid set of tags should be stored
        XCTAssertEqual(storedProductTagsCount, 4)
        XCTAssertNil(errorResponse)
    }

    func testSynchronizeProductTagsReturnsTagsUponPaginatedResponse() throws {
        // Given a stubed product-tags network response
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-all")
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-extra")
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-empty")
        XCTAssertEqual(storedProductTagsCount, 0)

        // When dispatching a `synchronizeAllProductTags` action
        var errorResponse: ProductTagActionError?
        waitForExpectation { (exp) in
            let action = ProductTagAction.synchronizeAllProductTags(siteID: sampleSiteID) { error in
                errorResponse = error
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then the combined set of tags should be stored
        XCTAssertEqual(storedProductTagsCount, 5)
        XCTAssertNil(errorResponse)
    }

    func testSynchronizeProductTagsUpdatesStoredTagsSuccessfulResponse() {
        // Given an initial stored tag and a stubed product-tags network response
        let initialTag = sampleTag(tagID: 34)
        storageManager.insertSampleProductTag(readOnlyProductTag: initialTag)
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-all")
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-empty")

        // When dispatching a `synchronizeAllProductTags` action
        var errorResponse: ProductTagActionError?
        waitForExpectation { (exp) in
            let action = ProductTagAction.synchronizeAllProductTags(siteID: sampleSiteID) { error in
                errorResponse = error
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then the initial tag should have it's values updated
        let updatedTag = viewStorage.loadProductTag(siteID: sampleSiteID, tagID: initialTag.tagID)
        XCTAssertEqual(initialTag.siteID, updatedTag?.siteID)
        XCTAssertEqual(initialTag.tagID, updatedTag?.tagID)
        XCTAssertNotEqual(initialTag.name, updatedTag?.name)
        XCTAssertNotEqual(initialTag.slug, updatedTag?.slug)
        XCTAssertNil(errorResponse)
    }

    func testSynchronizeProductTagsReturnsErrorUponPaginatedResponseError() {
        // Given a stubed first page tag response and second page generic-error network response
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-all")
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "generic_error")
        XCTAssertEqual(storedProductTagsCount, 0)

        // When dispatching a `synchronizeAllProductTags` action
        var errorResponse: ProductTagActionError?
        waitForExpectation { (exp) in
            let action = ProductTagAction.synchronizeAllProductTags(siteID: sampleSiteID) { error in
                errorResponse = error
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then first page of tags should be stored
        XCTAssertEqual(storedProductTagsCount, 4)

        // And error should contain correct fromPageNumber
        switch errorResponse {
        case let .tagsSynchronization(pageNumber, _):
            XCTAssertEqual(pageNumber, 2)
        case .none:
            XCTFail("errorResponse should not be nil")
        }
    }

    func testSynchronizeProductTagsReturnsErrorUponResponseError() {
        // Given a stubed generic-error network response
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "generic_error")
        XCTAssertEqual(storedProductTagsCount, 0)

        // When dispatching a `synchronizeAllProductTags` action
        var errorResponse: ProductTagActionError?
        waitForExpectation { (exp) in
            let action = ProductTagAction.synchronizeAllProductTags(siteID: sampleSiteID) { error in
                errorResponse = error
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then no tags should be stored
        XCTAssertEqual(storedProductTagsCount, 0)
        XCTAssertNotNil(errorResponse)
    }

    func testSynchronizeProductTagsReturnsErrorUponEmptyResponse() {
        // Given a an empty network response
        XCTAssertEqual(storedProductTagsCount, 0)

        // When dispatching a `synchronizeAllProductTags` action
        var errorResponse: ProductTagActionError?
        waitForExpectation { (exp) in
            let action = ProductTagAction.synchronizeAllProductTags(siteID: sampleSiteID) { error in
                errorResponse = error
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then no tags should be stored
        XCTAssertEqual(storedProductTagsCount, 0)
        XCTAssertNotNil(errorResponse)
    }

    func testAddProductTagAddsStoredTagSuccessfulResponse() {
        // Given a stubed product tag network response
        network.simulateResponse(requestUrlSuffix: "products/tags/batch", filename: "product-tags-created")

        // When dispatching a `addProductTags` action
        var result: Result<[Yosemite.ProductTag], Error>?
        waitForExpectation { (exp) in
            let action = ProductTagAction.addProductTags(siteID: sampleSiteID, tags: ["Round toe", "Flat"]) { (aResult) in
                result = aResult
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then the tag should be added
        let addedTag = viewStorage.loadProductTag(siteID: sampleSiteID, tagID: 36)
        XCTAssertNotNil(addedTag)
        XCTAssertEqual(addedTag?.siteID, sampleSiteID)
        XCTAssertEqual(addedTag?.tagID, 36)
        XCTAssertEqual(addedTag?.name, "Round toe")
        XCTAssertEqual(addedTag?.slug, "round-toe")
        XCTAssertNil(result?.failure)
    }

    func testAddProductTagReturnsErrorUponResponseError() {
        // Given a stubed generic-error network response
        network.simulateResponse(requestUrlSuffix: "products/tags/batch", filename: "generic_error")
        XCTAssertEqual(storedProductTagsCount, 0)

        // When dispatching a `addProductTags` action
        var result: Result<[Networking.ProductTag], Error>?
        waitForExpectation { (exp) in
            let action = ProductTagAction.addProductTags(siteID: sampleSiteID, tags: ["Round toe", "Flat"]) { (aResult) in
                result = aResult
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then no tags should be stored
        XCTAssertEqual(storedProductTagsCount, 0)
        XCTAssertNotNil(result?.failure)
    }

    func testAddProductTagReturnsErrorUponEmptyResponse() {
        // Given an empty network response
        XCTAssertEqual(storedProductTagsCount, 0)

        // When dispatching a `addProductTags` action
        var result: Result<[Networking.ProductTag], Error>?
        waitForExpectation { (exp) in
            let action = ProductTagAction.addProductTags(siteID: sampleSiteID, tags: ["Round toe", "Flat"]) { (aResult) in
                result = aResult
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then no tags should be stored
        XCTAssertEqual(storedProductTagsCount, 0)
        XCTAssertNotNil(result?.failure)
    }

    func testSynchronizeProductTagsDeletesUnusedTags() {
        // Given some stored product tags without product relationships
        let sampleTags = (1...5).map { id in
            return sampleTag(tagID: id)
        }
        sampleTags.forEach { tag in
            storageManager.insertSampleProductTag(readOnlyProductTag: tag)
        }
        XCTAssertEqual(storedProductTagsCount, sampleTags.count)

        // When dispatching a `synchronizeAllProductTags` action
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-all")
        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-empty")

        var errorResponse: ProductTagActionError?
        waitForExpectation { (exp) in
            let action = ProductTagAction.synchronizeAllProductTags(siteID: sampleSiteID) { error in
                errorResponse = error
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then new tag should be stored and old tags should be deleted
        XCTAssertEqual(storedProductTagsCount, 4)
        XCTAssertNil(errorResponse)
    }

    func testDeleteProductTagDeleteStoredTagSuccessfulResponse() {
        // Given a stubed product tag network response and a product tag stored locally
        network.simulateResponse(requestUrlSuffix: "products/tags/batch", filename: "product-tags-deleted")
        storageManager.insertSampleProductTag(readOnlyProductTag: sampleTag(tagID: 35))

        XCTAssertEqual(storedProductTagsCount, 1)

        // When dispatching a `deleteProductTags` action
        var result: Result<[Yosemite.ProductTag], Error>?
        waitForExpectation { (exp) in
            let action = ProductTagAction.deleteProductTags(siteID: sampleSiteID, ids: [35]) { (aResult) in
                result = aResult
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then the tag should be removed
        XCTAssertEqual(storedProductTagsCount, 0)
        XCTAssertNil(result?.failure)
    }

    func testDeleteProductTagReturnsErrorUponResponseError() {
        // Given a stubed generic-error network response
        network.simulateResponse(requestUrlSuffix: "products/tags/batch", filename: "generic_error")
        storageManager.insertSampleProductTag(readOnlyProductTag: sampleTag(tagID: 35))
        XCTAssertEqual(storedProductTagsCount, 1)

        // When dispatching a `deleteProductTags` action
        var result: Result<[Yosemite.ProductTag], Error>?
        waitForExpectation { (exp) in
            let action = ProductTagAction.deleteProductTags(siteID: sampleSiteID, ids: [35]) { (aResult) in
                result = aResult
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then one tags should be continue to be stored
        XCTAssertEqual(storedProductTagsCount, 1)
        XCTAssertNotNil(result?.failure)
    }

    func testDeleteProductTagReturnsErrorUponEmptyResponse() {
        // Given an empty network response
        storageManager.insertSampleProductTag(readOnlyProductTag: sampleTag(tagID: 35))
        XCTAssertEqual(storedProductTagsCount, 1)

        // When dispatching a `deleteProductTags` action
        var result: Result<[Yosemite.ProductTag], Error>?
        waitForExpectation { (exp) in
            let action = ProductTagAction.deleteProductTags(siteID: sampleSiteID, ids: [35]) { (aResult) in
                result = aResult
                exp.fulfill()
            }
            store.onAction(action)
        }

        // Then one tags should be continue to be stored
        XCTAssertEqual(storedProductTagsCount, 1)
        XCTAssertNotNil(result?.failure)
    }
}

private extension ProductTagStoreTests {
    func sampleTag(tagID: Int64) -> Networking.ProductTag {
        return Networking.ProductTag(siteID: sampleSiteID, tagID: tagID, name: "Sample", slug: "sample")
    }
}
