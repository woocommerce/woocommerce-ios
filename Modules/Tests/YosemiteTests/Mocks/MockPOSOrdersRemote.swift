import Networking

final class MockPOSOrdersRemote: POSOrdersRemoteProtocol {
    var updatePOSOrderCalled: Bool = false
    var spyUpdatePOSOrder: Order?
    var spyUpdatePOSOrderFields: [OrdersRemote.UpdateOrderField]?
    var spyUpdatePOSOrderCashPaymentChangeDueAmount: String?
    var updatePOSOrderResult: Result<Order, Error> = .success(Order.fake())
    func updatePOSOrder(siteID: Int64,
                        order: Order,
                        cashPaymentChangeDueAmount: String?,
                        fields: [OrdersRemote.UpdateOrderField]) async throws -> Order {
        updatePOSOrderCalled = true
        spyUpdatePOSOrder = order
        spyUpdatePOSOrderFields = fields
        spyUpdatePOSOrderCashPaymentChangeDueAmount = cashPaymentChangeDueAmount
        switch updatePOSOrderResult {
        case .success(let updatedOrder):
            return updatedOrder
        case .failure(let error):
            throw error
        }
    }

    var updatePOSOrderEmailCalled: Bool = false
    var spyUpdatePOSOrderEmailSiteID: Int64?
    var spyUpdatePOSOrderEmailOrderID: Int64?
    var spyUpdatePOSOrderEmailAddress: String?
    var updatePOSOrderEmailResult: Result<Void, Error> = .success(())

    func updatePOSOrderEmail(siteID: Int64, orderID: Int64, emailAddress: String) async throws {
        updatePOSOrderEmailCalled = true
        spyUpdatePOSOrderEmailSiteID = siteID
        spyUpdatePOSOrderEmailOrderID = orderID
        spyUpdatePOSOrderEmailAddress = emailAddress
        switch updatePOSOrderEmailResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    var createPOSOrderCalled: Bool = false
    var spyCreatePOSOrder: Order?
    var spyCreatePOSOrderFields: [OrdersRemote.CreateOrderField]?
    var createPOSOrderResult: Result<Order, Error>?
    func createPOSOrder(siteID: Int64,
                        order: Networking.Order,
                        fields: [OrdersRemote.CreateOrderField]) async throws -> Order {
        createPOSOrderCalled = true
        spyCreatePOSOrder = order
        spyCreatePOSOrderFields = fields

        // If a custom result is set, use it
        if let result = createPOSOrderResult {
            switch result {
            case .success(let customOrder):
                return customOrder
            case .failure(let error):
                throw error
            }
        }

        // By default, return the order that was passed in (simulating server echo)
        return order
    }

    var mockPagedOrdersResult: Result<PagedItems<Order>, Error> = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
    var loadPOSOrdersCalled = false
    var spySiteID: Int64?
    var spyPageNumber: Int?
    var spyPageSize: Int?

    func loadPOSOrders(siteID: Int64, pageNumber: Int, pageSize: Int) async throws -> PagedItems<Order> {
        loadPOSOrdersCalled = true
        spySiteID = siteID
        spyPageNumber = pageNumber
        spyPageSize = pageSize

        switch mockPagedOrdersResult {
        case .success(let pagedOrders):
            return pagedOrders
        case .failure(let error):
            throw error
        }
    }

    var mockSearchPagedOrdersResult: Result<PagedItems<Order>, Error> = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
    var searchPOSOrdersCalled = false
    var spySearchTerm: String?

    func searchPOSOrders(siteID: Int64, searchTerm: String, pageNumber: Int, pageSize: Int) async throws -> PagedItems<Order> {
        searchPOSOrdersCalled = true
        spySiteID = siteID
        spySearchTerm = searchTerm
        spyPageNumber = pageNumber
        spyPageSize = pageSize

        switch mockSearchPagedOrdersResult {
        case .success(let pagedOrders):
            return pagedOrders
        case .failure(let error):
            throw error
        }
    }

    var loadPOSOrderCalled = false
    var spyLoadPOSOrderID: Int64?
    var loadPOSOrderResult: Result<Order, Error> = .success(Order.fake())

    func loadPOSOrder(siteID: Int64, orderID: Int64) async throws -> Order {
        loadPOSOrderCalled = true
        spySiteID = siteID
        spyLoadPOSOrderID = orderID

        switch loadPOSOrderResult {
        case .success(let order):
            return order
        case .failure(let error):
            throw error
        }
    }

    var loadPOSOrdersByIDsCalled = false
    var loadPOSOrdersByIDsResult: Result<[Order], Error> = .success([])

    func loadPOSOrders(siteID: Int64, orderIDs: [Int64]) async throws -> [Order] {
        loadPOSOrdersByIDsCalled = true
        spySiteID = siteID

        switch loadPOSOrdersByIDsResult {
        case .success(let orders):
            return orders
        case .failure(let error):
            throw error
        }
    }
}
