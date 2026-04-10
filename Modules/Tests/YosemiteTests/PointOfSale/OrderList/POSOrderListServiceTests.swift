import XCTest
@testable import Yosemite
import struct NetworkingCore.PagedItems
import struct NetworkingCore.Order
import enum NetworkingCore.OrderStatusEnum
import WooFoundation

final class POSOrderListServiceTests: XCTestCase {
    private let siteID: Int64 = 13092
    private var orderProvider: POSOrderListServiceProtocol!
    private var mockOrdersRemote: MockPOSOrdersRemote!

    override func setUp() {
        super.setUp()
        mockOrdersRemote = MockPOSOrdersRemote()
        orderProvider = POSOrderListService(
            siteID: siteID,
            ordersRemote: mockOrdersRemote,
            currencyFormatter: CurrencyFormatter(currencySettings: CurrencySettings())
        )
    }

    override func tearDown() {
        orderProvider = nil
        mockOrdersRemote = nil
        super.tearDown()
    }

    func test_PointOfSaleOrderServiceProtocol_when_fails_request_with_requestFailed_then_throws_error() async throws {
        let expectedError = POSOrderListServiceError.requestFailed
        mockOrdersRemote.mockPagedOrdersResult = .failure(expectedError)

        do {
            _ = try await orderProvider.providePointOfSaleOrders(pageNumber: 1)
            XCTFail("Expected an error, but got success.")
        } catch {
            XCTAssertEqual(error as? POSOrderListServiceError, expectedError)
        }
    }

    func test_PointOfSaleOrderServiceProtocol_when_empty_data_for_non_first_page_of_orders_then_returns_empty_orders_and_no_next_page() async throws {
        mockOrdersRemote.mockPagedOrdersResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))

        let pagedOrders = try await orderProvider.providePointOfSaleOrders(pageNumber: 2)

        XCTAssertTrue(pagedOrders.items.isEmpty)
        XCTAssertFalse(pagedOrders.hasMorePages)
    }

    func test_PointOfSaleOrderServiceProtocol_provides_no_orders_when_store_has_no_orders() async throws {
        mockOrdersRemote.mockPagedOrdersResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))

        let pagedOrders = try await orderProvider.providePointOfSaleOrders(pageNumber: 1)

        XCTAssertTrue(pagedOrders.items.isEmpty)
        XCTAssertTrue(mockOrdersRemote.loadPOSOrdersCalled)
        XCTAssertEqual(mockOrdersRemote.spyPageNumber, 1)
        XCTAssertEqual(mockOrdersRemote.spyPageSize, 25)
    }

    func test_PointOfSaleOrderServiceProtocol_provides_orders_when_store_has_orders() async throws {
        let mockOrder = Order.fake().copy(
            orderID: 1001,
            number: "1001",
            status: .completed,
            total: "25.99"
        )
        mockOrdersRemote.mockPagedOrdersResult = .success(PagedItems(items: [mockOrder],
                                                                     hasMorePages: false,
                                                                     totalItems: 1))

        let pagedOrders = try await orderProvider.providePointOfSaleOrders(pageNumber: 1)

        XCTAssertEqual(pagedOrders.items.count, 1)
        XCTAssertTrue(mockOrdersRemote.loadPOSOrdersCalled)
        XCTAssertEqual(mockOrdersRemote.spyPageNumber, 1)
        XCTAssertEqual(mockOrdersRemote.spyPageSize, 25)
        XCTAssertEqual(pagedOrders.items.first?.id, 1001)
    }

    func test_PointOfSaleOrderServiceProtocol_returns_correct_pagination_when_more_pages_available() async throws {
        let mockOrders = [
            Order.fake().copy(orderID: 1001, number: "1001", status: .completed, total: "25.99"),
            Order.fake().copy(orderID: 1002, number: "1002", status: .completed, total: "15.50")
        ]
        mockOrdersRemote.mockPagedOrdersResult = .success(PagedItems(items: mockOrders,
                                                                     hasMorePages: true,
                                                                     totalItems: 10))

        let pagedOrders = try await orderProvider.providePointOfSaleOrders(pageNumber: 1)

        XCTAssertEqual(pagedOrders.items.count, 2)
        XCTAssertTrue(pagedOrders.hasMorePages)
        XCTAssertEqual(pagedOrders.totalItems, 10)
        XCTAssertTrue(mockOrdersRemote.loadPOSOrdersCalled)
    }

    func test_providePointOfSaleOrders_uses_passed_page_number() async throws {
        mockOrdersRemote.mockPagedOrdersResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))

        _ = try await orderProvider.providePointOfSaleOrders(pageNumber: 5)

        XCTAssertTrue(mockOrdersRemote.loadPOSOrdersCalled)
        XCTAssertEqual(mockOrdersRemote.spyPageNumber, 5)
        XCTAssertEqual(mockOrdersRemote.spyPageSize, 25)
    }

    func test_providePointOfSaleOrders_handles_fetch_error() async {
        mockOrdersRemote.mockPagedOrdersResult = .failure(TestError.expectedError)

        do {
            _ = try await orderProvider.providePointOfSaleOrders(pageNumber: 1)
            XCTFail("Expected error to be thrown")
        } catch POSOrderListServiceError.requestFailed {
            // Expected
        } catch {
            XCTFail("Unexpected error occurred: \(error)")
        }
    }

    func test_providePointOfSaleOrders_handles_empty_results() async throws {
        mockOrdersRemote.mockPagedOrdersResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))

        let pagedOrders = try await orderProvider.providePointOfSaleOrders(pageNumber: 1)

        XCTAssertEqual(pagedOrders.items.count, 0)
        XCTAssertTrue(mockOrdersRemote.loadPOSOrdersCalled)
    }

    func test_providePointOfSaleOrders_passes_correct_site_id() async throws {
        mockOrdersRemote.mockPagedOrdersResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))

        _ = try await orderProvider.providePointOfSaleOrders(pageNumber: 1)

        XCTAssertEqual(mockOrdersRemote.spySiteID, siteID)
    }

    func test_providePointOfSaleOrders_uses_default_page_size() async throws {
        mockOrdersRemote.mockPagedOrdersResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))

        _ = try await orderProvider.providePointOfSaleOrders(pageNumber: 0)

        XCTAssertEqual(mockOrdersRemote.spyPageSize, 25)
    }
}

private extension POSOrderListServiceTests {
    enum TestError: Error {
        case expectedError
    }
}
