import Combine
import Testing
import UIKit
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
@Suite(.serialized)
struct ProductsViewControllerTests {
    @Test
    func test_loading_failure_and_retry_keep_content_in_the_main_table() throws {
        // Given
        let originalStores = ServiceLocator.stores
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        ServiceLocator.setStores(stores)
        defer { ServiceLocator.setStores(originalStores) }
        var completeSync: ((Result<Bool, Error>) -> Void)?
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, _, onCompletion) = action else { return }
            completeSync = onCompletion
        }
        let controller = ProductsViewController(siteID: Int64.max,
                                                 resultsController: makeResultsController(storage: MockStorageManager(), siteID: Int64.max),
                                                 selectedProduct: Just<Product?>(nil).eraseToAnyPublisher(),
                                                 navigateToContent: { _ in })
        controller.loadViewIfNeeded()
        let table = try #require(controller.tableView)
        let refreshControl = try #require(table.refreshControl)

        // When: the first page is loading
        controller.sync(pageNumber: 1, pageSize: 25, reason: nil, onCompletion: nil)

        // Then: placeholders are non-interactive rows in the main table
        #expect(table.numberOfSections == 1)
        #expect(table.numberOfRows(inSection: 0) == 3)
        let firstRow = IndexPath(row: 0, section: 0)
        #expect(controller.tableView(table, willSelectRowAt: firstRow) == nil)
        #expect(controller.tableView(table, trailingSwipeActionsConfigurationForRowAt: firstRow) == nil)
        #expect(controller.children.isEmpty)

        // When: the request fails
        let failSync = try #require(completeSync)
        failSync(.failure(URLError(.notConnectedToInternet)))

        // Then: empty content stays in that table, with the same refresh control
        #expect((0..<table.numberOfSections).allSatisfy { table.numberOfRows(inSection: $0) == 0 })
        #expect(table.tableFooterView is ListEmptyView)
        #expect(controller.children.isEmpty)
        #expect(table.refreshControl === refreshControl)

        // When: retry completes with an empty result
        controller.sync(pageNumber: 1, pageSize: 25, reason: nil, onCompletion: nil)
        #expect(table.numberOfRows(inSection: 0) == 3)
        #expect(!(table.tableFooterView is ListEmptyView))
        let finishRetry = try #require(completeSync)
        finishRetry(.success(false))

        // Then
        #expect((0..<table.numberOfSections).allSatisfy { table.numberOfRows(inSection: $0) == 0 })
        #expect(table.tableFooterView is ListEmptyView)
        #expect(controller.tableView === table)
        #expect(table.refreshControl === refreshControl)
    }

    @Test
    func test_products_arriving_during_initial_sync_replace_placeholders_before_selection() async throws {
        // Given
        let originalStores = ServiceLocator.stores
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        ServiceLocator.setStores(stores)
        defer { ServiceLocator.setStores(originalStores) }
        let storage = MockStorageManager()
        let selectedProduct = CurrentValueSubject<Product?, Never>(nil)
        var completeSync: ((Result<Bool, Error>) -> Void)?
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, _, onCompletion) = action else { return }
            completeSync = onCompletion
        }
        let controller = ProductsViewController(siteID: 123,
                                                 resultsController: makeResultsController(storage: storage, siteID: 123),
                                                 selectedProduct: selectedProduct.eraseToAnyPublisher(),
                                                 navigateToContent: { _ in })
        controller.loadViewIfNeeded()
        let table = try #require(controller.tableView)
        controller.sync(pageNumber: 1, pageSize: 25, reason: nil, onCompletion: nil)
        try #require(table.numberOfRows(inSection: 0) == 3)

        // When: Search adds products to the cache before the list request completes
        let products = (1...4).map { index in
            Product.fake().copy(siteID: 123, productID: Int64(index), name: "Product \(index)")
        }
        try await insert(products, into: storage)

        // Then: the table uses real product indexes before selection is published
        try #require(table.numberOfRows(inSection: 0) == 4)
        selectedProduct.send(products[3])
        #expect(table.indexPathForSelectedRow == IndexPath(row: 3, section: 0))
        #expect(controller.tableView(table, willSelectRowAt: IndexPath(row: 3, section: 0)) != nil)

        // When: the original request completes without changing the cached results
        let finishSync = try #require(completeSync)
        finishSync(.success(false))

        // Then: completion keeps the existing selection
        #expect(table.numberOfRows(inSection: 0) == 4)
        #expect(table.indexPathForSelectedRow == IndexPath(row: 3, section: 0))
    }

}

private extension ProductsViewControllerTests {
    func insert(_ products: [Product], into storageManager: MockStorageManager) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            storageManager.performAndSave({ storage in
                let storedProducts = products.map { product in
                    let stored = storage.insertNewObject(ofType: StorageProduct.self)
                    stored.update(with: product)
                    return stored
                }
                try storage.obtainPermanentIDs(for: storedProducts)
            }, completion: { continuation.resume(with: $0) }, on: .main)
        }
    }

    func makeResultsController(storage: MockStorageManager, siteID: Int64) -> ResultsController<StorageProduct> {
        ResultsController(storageManager: storage,
                          matching: NSPredicate(format: "siteID == %lld", siteID),
                          sortedBy: [NSSortDescriptor(key: "name", ascending: true)])
    }
}
