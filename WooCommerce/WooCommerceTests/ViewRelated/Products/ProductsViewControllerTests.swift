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
    func test_sync_when_loading_fails_and_retries_then_keeps_content_in_the_main_table() throws {
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
        let refreshControl = try attachedRefreshControl(in: table)

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
        #expect(refreshControl.superview === table)

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
        #expect(refreshControl.superview === table)
    }

    @Test
    func test_sync_when_products_arrive_during_initial_load_then_replaces_placeholders_before_selection() async throws {
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
        let firstRow = IndexPath(row: 0, section: 0)
        let loadingCell = controller.tableView(table, cellForRowAt: firstRow)
        #expect(loadingCell is ProductsTabProductTableViewCell)
        #expect(loadingCell.accessibilityIdentifier == nil)
        #expect(!loadingCell.isUserInteractionEnabled)

        // When: Search adds products to the cache before the list request completes
        let products = (1...4).map { index in
            Product.fake().copy(siteID: 123, productID: Int64(index), name: "Product \(index)")
        }
        try await insert(products, into: storage)

        // Then: the table uses real product indexes before selection is published
        try #require(table.numberOfRows(inSection: 0) == 4)
        let productCell = controller.tableView(table, cellForRowAt: firstRow)
        #expect(productCell.reuseIdentifier != loadingCell.reuseIdentifier)
        #expect(productCell.isUserInteractionEnabled)
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

    @Test
    func test_refresh_when_products_are_deleted_and_reordered_then_keeps_displayed_rows_and_actions_consistent() async throws {
        // Given
        let originalStores = ServiceLocator.stores
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        ServiceLocator.setStores(stores)
        defer { ServiceLocator.setStores(originalStores) }
        let storage = MockStorageManager()
        let products = ["A", "B", "C"].enumerated().map {
            Product.fake().copy(siteID: 123, productID: Int64($0.offset + 1), name: $0.element)
        }
        try await insert(products, into: storage)
        var selectedIDs: [Int64] = []
        let controller = ProductsViewController(siteID: 123,
                                                 resultsController: makeResultsController(storage: storage, siteID: 123),
                                                 selectedProduct: Just<Product?>(nil).eraseToAnyPublisher(),
                                                 navigateToContent: { content in
                                                     if case let .productForm(product) = content {
                                                         selectedIDs.append(product.productID)
                                                     }
                                                 })
        controller.loadViewIfNeeded()
        let table = try #require(controller.tableView)
        let refreshControl = try attachedRefreshControl(in: table)
        let completeSync = try await startRefresh(refreshControl, stores: stores)
        try #require(table.numberOfRows(inSection: 0) == 3)

        // When: the store removes A and moves B after C during the refresh.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            storage.performAndSave({ storage in
                if let deletedProduct = storage.loadProduct(siteID: 123, productID: 1) {
                    storage.deleteObject(deletedProduct)
                }
                storage.loadProduct(siteID: 123, productID: 2)?.name = "Z"
            }, completion: { continuation.resume(with: $0) }, on: .main)
        }

        // Then: cells retain their displayed identities; actions ignore deletions and use identity after reordering.
        #expect(table.numberOfRows(inSection: 0) == 3)
        for (index, name) in ["A", "B", "C"].enumerated() {
            let indexPath = IndexPath(row: index, section: 0)
            #expect(controller.tableView(table, cellForRowAt: indexPath).accessibilityIdentifier == name)
            controller.tableView(table, didSelectRowAt: indexPath)
        }
        #expect(selectedIDs == [2, 3])

        // When: dismissal completes and the latest data is rendered.
        await finishRefresh(controller, completeSync: completeSync)

        // Then
        #expect(table.numberOfRows(inSection: 0) == 2)
        #expect(controller.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0)).accessibilityIdentifier == "C")
        #expect(controller.tableView(table, cellForRowAt: IndexPath(row: 1, section: 0)).accessibilityIdentifier == "Z")
    }

    @Test
    func test_sync_when_next_page_sorts_before_loaded_products_locally_then_appends_it_after_them() async throws {
        // Given
        let originalStores = ServiceLocator.stores
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        ServiceLocator.setStores(stores)
        defer { ServiceLocator.setStores(originalStores) }
        let storage = MockStorageManager()
        let controller = ProductsViewController(siteID: 123,
                                                 resultsController: makeResultsController(storage: storage, siteID: 123),
                                                 selectedProduct: Just<Product?>(nil).eraseToAnyPublisher(),
                                                 navigateToContent: { _ in })
        controller.loadViewIfNeeded()
        let table = try #require(controller.tableView)

        // The store's collation can sort a name earlier than the local sort does.
        try await loadPage(1, names: ["Awesome Wooden Shoes", "オビツキューピー招き猫セット"], firstID: 1,
                           controller: controller, storage: storage, stores: stores)

        // When: the next page has names that sort before the last loaded product locally
        try await loadPage(2, names: ["Casual Blue Women's Shirt", "Durable Wooden Hat"], firstID: 3,
                           controller: controller, storage: storage, stores: stores)

        // Then
        #expect(displayedNames(in: table, controller: controller) == [
            "Awesome Wooden Shoes",
            "オビツキューピー招き猫セット",
            "Casual Blue Women's Shirt",
            "Durable Wooden Hat"
        ])
    }

    @Test
    func test_refresh_when_sync_fails_then_keeps_products_in_page_order() async throws {
        // Given
        let originalStores = ServiceLocator.stores
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        ServiceLocator.setStores(stores)
        defer { ServiceLocator.setStores(originalStores) }
        let storage = MockStorageManager()
        let controller = ProductsViewController(siteID: 123,
                                                 resultsController: makeResultsController(storage: storage, siteID: 123),
                                                 selectedProduct: Just<Product?>(nil).eraseToAnyPublisher(),
                                                 navigateToContent: { _ in })
        controller.loadViewIfNeeded()
        let table = try #require(controller.tableView)
        try await loadPage(1, names: ["Awesome Wooden Shoes", "オビツキューピー招き猫セット"], firstID: 1,
                           controller: controller, storage: storage, stores: stores)
        try await loadPage(2, names: ["Casual Blue Women's Shirt"], firstID: 3,
                           controller: controller, storage: storage, stores: stores)
        let refreshControl = try attachedRefreshControl(in: table)

        // When: another flow saves a product during the refresh, then the refresh fails
        let completeSync = try await startRefresh(refreshControl, stores: stores)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            storage.performAndSave({ storage in
                storage.loadProduct(siteID: 123, productID: 1)?.price = "10"
            }, completion: { continuation.resume(with: $0) }, on: .main)
        }
        await finishRefresh(controller, completeSync: completeSync, result: .failure(NSError(domain: "test", code: 0)))

        // Then
        #expect(displayedNames(in: table, controller: controller) == [
            "Awesome Wooden Shoes",
            "オビツキューピー招き猫セット",
            "Casual Blue Women's Shirt"
        ])
    }

    @Test
    func test_refresh_when_next_page_syncs_before_refresh_is_rendered_then_keeps_products_in_page_order() async throws {
        // Given
        let originalStores = ServiceLocator.stores
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        ServiceLocator.setStores(stores)
        defer { ServiceLocator.setStores(originalStores) }
        let storage = MockStorageManager()
        let controller = ProductsViewController(siteID: 123,
                                                 resultsController: makeResultsController(storage: storage, siteID: 123),
                                                 selectedProduct: Just<Product?>(nil).eraseToAnyPublisher(),
                                                 navigateToContent: { _ in })
        controller.loadViewIfNeeded()
        let table = try #require(controller.tableView)
        let refreshControl = try attachedRefreshControl(in: table)
        let completeFirstPage = try await startRefresh(refreshControl, stores: stores)

        try await insert(makeProducts(["Awesome Wooden Shoes", "オビツキューピー招き猫セット"], firstID: 1), into: storage)

        // When: the next page loads after the first page completes, but before the refresh is rendered.
        var subscription: AnyCancellable?
        await withCheckedContinuation { continuation in
            subscription = controller.onDataReloaded.first().sink { continuation.resume() }
            completeFirstPage(.success(true))
            var completeNextPage: ((Result<Bool, Error>) -> Void)?
            stores.whenReceivingAction(ofType: ProductAction.self) { action in
                guard case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, _, onCompletion) = action else { return }
                completeNextPage = onCompletion
            }
            controller.sync(pageNumber: 2, pageSize: 1, reason: nil, onCompletion: nil)
            // `MockStorageManager` writes synchronously, so the page is stored before the refresh renders.
            storage.performAndSave({ storage in
                let stored = storage.insertNewObject(ofType: StorageProduct.self)
                stored.update(with: Product.fake().copy(siteID: 123, productID: 3, name: "Casual Blue Women's Shirt"))
            }, completion: nil, on: .main)
            completeNextPage?(.success(false))
        }
        subscription?.cancel()

        // Then
        #expect(displayedNames(in: table, controller: controller) == [
            "Awesome Wooden Shoes",
            "オビツキューピー招き猫セット",
            "Casual Blue Women's Shirt"
        ])
    }

    @Test
    func test_refresh_when_an_offscreen_product_is_selected_then_scrolls_to_selection_after_refresh() async throws {
        // Given
        let originalStores = ServiceLocator.stores
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        ServiceLocator.setStores(stores)
        defer { ServiceLocator.setStores(originalStores) }
        let storage = MockStorageManager()
        let products = (1...30).map { index in
            Product.fake().copy(siteID: 123, productID: Int64(index), name: String(format: "Product %02d", index))
        }
        try await insert(products, into: storage)
        let selectedProduct = CurrentValueSubject<Product?, Never>(nil)
        let controller = ProductsViewController(siteID: 123,
                                                 resultsController: makeResultsController(storage: storage, siteID: 123),
                                                 selectedProduct: selectedProduct.eraseToAnyPublisher(),
                                                 navigateToContent: { _ in })
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()
        let table = try #require(controller.tableView)
        table.layoutIfNeeded()
        let selectedIndexPath = IndexPath(row: products.count - 1, section: 0)
        try #require(!table.bounds.intersects(table.rectForRow(at: selectedIndexPath)))
        let refreshControl = try attachedRefreshControl(in: table)
        let completeSync = try await startRefresh(refreshControl, stores: stores)

        // When: Search selects an offscreen product while the list refresh is pending.
        selectedProduct.send(products.last)

        // Then: selection remains deferred with the other presentation updates.
        #expect(table.indexPathForSelectedRow == nil)
        #expect(!table.bounds.intersects(table.rectForRow(at: selectedIndexPath)))

        // When
        await finishRefresh(controller, completeSync: completeSync)
        table.layoutIfNeeded()

        // Then
        #expect(table.indexPathForSelectedRow == selectedIndexPath)
        #expect(table.bounds.intersects(table.rectForRow(at: selectedIndexPath)))
    }
}

private extension ProductsViewControllerTests {
    func attachedRefreshControl(in table: UITableView) throws -> UIRefreshControl {
        // Before iOS 26 the control is added as a subview rather than assigned to table.refreshControl.
        try #require(table.subviews.compactMap { $0 as? UIRefreshControl }.first)
    }

    func startRefresh(_ refreshControl: UIRefreshControl, stores: MockStoresManager) async throws -> ((Result<Bool, Error>) -> Void) {
        var completeSync: ((Result<Bool, Error>) -> Void)?
        await withCheckedContinuation { continuation in
            stores.whenReceivingAction(ofType: ProductAction.self) { action in
                guard case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, _, onCompletion) = action else {
                    return
                }
                completeSync = onCompletion
                continuation.resume()
            }
            refreshControl.beginRefreshing()
            refreshControl.sendActions(for: .valueChanged)
        }
        return try #require(completeSync)
    }

    func finishRefresh(_ controller: ProductsViewController,
                       completeSync: (Result<Bool, Error>) -> Void,
                       result: Result<Bool, Error> = .success(false)) async {
        var subscription: AnyCancellable?
        await withCheckedContinuation { continuation in
            subscription = controller.onDataReloaded.first().sink { continuation.resume() }
            completeSync(result)
        }
        subscription?.cancel()
    }

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

    /// Syncs a page and stores its products before the sync completes, like `ProductStore` does.
    func loadPage(_ pageNumber: Int,
                  names: [String],
                  firstID: Int64,
                  controller: ProductsViewController,
                  storage: MockStorageManager,
                  stores: MockStoresManager) async throws {
        var completeSync: ((Result<Bool, Error>) -> Void)?
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, _, onCompletion) = action else { return }
            completeSync = onCompletion
        }
        controller.sync(pageNumber: pageNumber, pageSize: names.count, reason: nil, onCompletion: nil)
        try await insert(makeProducts(names, firstID: firstID), into: storage)
        let finishPage = try #require(completeSync)
        finishPage(.success(true))
    }

    func makeProducts(_ names: [String], firstID: Int64) -> [Product] {
        names.enumerated().map { index, name in
            Product.fake().copy(siteID: 123, productID: firstID + Int64(index), name: name)
        }
    }

    func displayedNames(in table: UITableView, controller: ProductsViewController) -> [String?] {
        (0..<table.numberOfRows(inSection: 0)).map {
            controller.tableView(table, cellForRowAt: IndexPath(row: $0, section: 0)).accessibilityIdentifier
        }
    }

    func makeResultsController(storage: MockStorageManager, siteID: Int64) -> ResultsController<StorageProduct> {
        ResultsController(storageManager: storage,
                          matching: NSPredicate(format: "siteID == %lld", siteID),
                          sortOrder: .nameAscending)
    }
}
