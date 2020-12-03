
import XCTest
import Foundation
import Yosemite

import protocol Storage.StorageManagerType
import protocol Storage.StorageType

@testable import WooCommerce

private typealias CellViewModel = OrderSearchStarterViewModel.CellViewModel

/// Tests for `OrderSearchStarterViewModel`
///
final class OrderSearchStarterViewModelTests: XCTestCase {
    private let siteID: Int64 = 1_000_000

    private var storageManager: StorageManagerType!

    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_it_loads_all_the_OrderStatus_for_the_given_site() {
        // Given
        let viewModel = OrderSearchStarterViewModel(siteID: siteID, storageManager: storageManager)

        let expectedItems = [
            insertOrderStatus(siteID: siteID, status: .completed),
            insertOrderStatus(siteID: siteID, status: .failed),
            insertOrderStatus(siteID: siteID, status: .processing),
        ]

        let unexpectedItem = insertOrderStatus(siteID: 511_315, status: .pending)

        // When
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Then
        XCTAssertEqual(viewModel.numberOfObjects, expectedItems.count)
        XCTAssertEqual(viewModel.cellViewModels.slugs, expectedItems.slugs)
        XCTAssertFalse(viewModel.cellViewModels.contains(where: { $0.slug == unexpectedItem.slug }))
    }

    func test_it_sorts_the_OrderStatuses_by_slug() {
        // Given
        let viewModel = OrderSearchStarterViewModel(siteID: siteID, storageManager: storageManager)

        insert(OrderStatus(name: "autem", siteID: siteID, slug: "delta", total: 0))
        insert(OrderStatus(name: "dolores", siteID: siteID, slug: "charlie", total: 0))
        insert(OrderStatus(name: "fugit", siteID: siteID, slug: "echo", total: 0))
        insert(OrderStatus(name: "itaque", siteID: siteID, slug: "alpha", total: 0))
        insert(OrderStatus(name: "eos", siteID: siteID, slug: "beta", total: 0))

        // When
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Then
        let expectedSlugs = ["alpha", "beta", "charlie", "delta", "echo"]
        XCTAssertEqual(viewModel.cellViewModels.slugs, expectedSlugs)
    }

    func test_it_returns_the_name_slug_and_total_in_the_CellViewModel() {
        // Given
        let viewModel = OrderSearchStarterViewModel(siteID: siteID, storageManager: storageManager)

        insert(OrderStatus(name: "autem", siteID: siteID, slug: "delta", total: 18))
        insert(OrderStatus(name: "dolores", siteID: siteID, slug: "charlie", total: 73))

        viewModel.activateAndForwardUpdates(to: UITableView())

        // When
        // Retrieve "delta" which is the second row
        let cellViewModel = viewModel.cellViewModel(at: IndexPath(row: 1, section: 0))

        // Then
        XCTAssertEqual(cellViewModel.name, "autem")
        XCTAssertEqual(cellViewModel.slug, "delta")
        XCTAssertEqual(cellViewModel.total,
                       NumberFormatter.localizedString(from: NSNumber(value: 18), number: .none))
    }

    func test_total_given_an_OrderStatus_total_of_more_than_ninety_nine_it_uses_the_complete_localized_number() {
        // Given
        let viewModel = OrderSearchStarterViewModel(siteID: siteID,
                                                    storageManager: storageManager,
                                                    locale: Locale(identifier: "en_US"))

        insert(OrderStatus(name: "Processing", siteID: siteID, slug: "slug", total: 2187))

        viewModel.activateAndForwardUpdates(to: UITableView())

        // When
        let cellViewModel = viewModel.cellViewModel(at: IndexPath(row: 0, section: 0))

        // Then
        XCTAssertEqual(cellViewModel.total, "2,187")
    }

    func test_total_given_a_zero_OrderStatus_total_it_uses_a_zero_string() {
        // Given
        let viewModel = OrderSearchStarterViewModel(siteID: siteID,
                                                    storageManager: storageManager,
                                                    locale: Locale(identifier: "en_US"))

        insert(OrderStatus(name: "Processing", siteID: siteID, slug: "slug", total: 0))

        viewModel.activateAndForwardUpdates(to: UITableView())

        // When
        let cellViewModel = viewModel.cellViewModel(at: IndexPath(row: 0, section: 0))

        // Then
        XCTAssertEqual(cellViewModel.total, "0")
    }
}

// MARK: - Helpers

private extension OrderSearchStarterViewModel {
    /// Returns all the `CellViewModel` based on the fetched `OrderStatus`.
    ///
    var cellViewModels: [CellViewModel] {
        (0..<numberOfObjects).map { cellViewModel(at: IndexPath(row: $0, section: 0)) }
    }
}

private extension Array where Element == OrderStatus {
    var slugs: [String] {
        map(\.slug)
    }
}

private extension Array where Element == CellViewModel {
    var slugs: [String] {
        map(\.slug)
    }
}

// MARK: - Fixtures

private extension OrderSearchStarterViewModelTests {
    @discardableResult
    func insert(_ readOnlyOrderStatus: OrderStatus) -> OrderStatus {
        let storageOrderStatus = storage.insertNewObject(ofType: StorageOrderStatus.self)
        storageOrderStatus.update(with: readOnlyOrderStatus)
        return readOnlyOrderStatus
    }

    @discardableResult
    func insertOrderStatus(siteID: Int64, status: OrderStatusEnum) -> OrderStatus {
        let readOnlyOrderStatus = OrderStatus(name: status.rawValue,
                                              siteID: siteID,
                                              slug: status.rawValue,
                                              total: 0)

        return insert(readOnlyOrderStatus)
    }
}
