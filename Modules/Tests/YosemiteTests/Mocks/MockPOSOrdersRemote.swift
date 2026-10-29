import Networking
import Synchronization

@dynamicMemberLookup
final class MockPOSOrdersRemote: POSOrdersRemoteProtocol {
    struct State {
        var updatePOSOrderCalled: Bool = false
        var spyUpdatePOSOrder: Order?
        var spyUpdatePOSOrderFields: [OrdersRemote.UpdateOrderField]?
        var spyUpdatePOSOrderCashPaymentChangeDueAmount: String?
        var updatePOSOrderResult: Result<Order, Error> = .success(Order.fake())

        var updatePOSOrderEmailCalled: Bool = false
        var spyUpdatePOSOrderEmailSiteID: Int64?
        var spyUpdatePOSOrderEmailOrderID: Int64?
        var spyUpdatePOSOrderEmailAddress: String?
        var updatePOSOrderEmailResult: Result<Void, Error> = .success(())

        var createPOSOrderCalled: Bool = false
        var spyCreatePOSOrder: Order?
        var spyCreatePOSOrderFields: [OrdersRemote.CreateOrderField]?
        var createPOSOrderResult: Result<Order, Error>?

        var mockPagedOrdersResult: Result<PagedItems<Order>, Error> = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
        var loadPOSOrdersCalled = false
        var spySiteID: Int64?
        var spyPageNumber: Int?
        var spyPageSize: Int?

        var mockSearchPagedOrdersResult: Result<PagedItems<Order>, Error> = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
        var searchPOSOrdersCalled = false
        var spySearchTerm: String?

        var loadPOSOrderCalled = false
        var spyLoadPOSOrderID: Int64?
        var loadPOSOrderResult: Result<Order, Error> = .success(Order.fake())

        var loadPOSOrdersByIDsCalled = false
        var loadPOSOrdersByIDsResult: Result<[Order], Error> = .success([])

        var addPOSOrderNoteCalled = false
        var spyAddPOSOrderNoteOrderID: Int64?
        var spyAddPOSOrderNoteIsCustomerNote: Bool?
        var spyAddPOSOrderNoteText: String?
        var addPOSOrderNoteError: Error?
    }

    private let state = Mutex(State())

    subscript<T: Sendable>(dynamicMember keyPath: WritableKeyPath<State, T>) -> T {
        get { state.withLock { $0[keyPath: keyPath] } }
        set { state.withLock { $0[keyPath: keyPath] = newValue } }
    }

    func updatePOSOrder(siteID: Int64,
                        order: Order,
                        cashPaymentChangeDueAmount: String?,
                        fields: [OrdersRemote.UpdateOrderField]) async throws -> Order {
        try state.withLock {
            $0.updatePOSOrderCalled = true
            $0.spyUpdatePOSOrder = order
            $0.spyUpdatePOSOrderFields = fields
            $0.spyUpdatePOSOrderCashPaymentChangeDueAmount = cashPaymentChangeDueAmount
            return try $0.updatePOSOrderResult.get()
        }
    }

    func updatePOSOrderEmail(siteID: Int64, orderID: Int64, emailAddress: String) async throws {
        try state.withLock {
            $0.updatePOSOrderEmailCalled = true
            $0.spyUpdatePOSOrderEmailSiteID = siteID
            $0.spyUpdatePOSOrderEmailOrderID = orderID
            $0.spyUpdatePOSOrderEmailAddress = emailAddress
            try $0.updatePOSOrderEmailResult.get()
        }
    }

    func createPOSOrder(siteID: Int64,
                        order: Networking.Order,
                        fields: [OrdersRemote.CreateOrderField]) async throws -> Order {
        try state.withLock {
            $0.createPOSOrderCalled = true
            $0.spyCreatePOSOrder = order
            $0.spyCreatePOSOrderFields = fields

            // If a custom result is set, use it
            if let result = $0.createPOSOrderResult {
                return try result.get()
            }

            // By default, return the order that was passed in (simulating server echo)
            return order
        }
    }

    func loadPOSOrders(siteID: Int64, pageNumber: Int, pageSize: Int) async throws -> PagedItems<Order> {
        try state.withLock {
            $0.loadPOSOrdersCalled = true
            $0.spySiteID = siteID
            $0.spyPageNumber = pageNumber
            $0.spyPageSize = pageSize
            return try $0.mockPagedOrdersResult.get()
        }
    }

    func searchPOSOrders(siteID: Int64, searchTerm: String, pageNumber: Int, pageSize: Int) async throws -> PagedItems<Order> {
        try state.withLock {
            $0.searchPOSOrdersCalled = true
            $0.spySiteID = siteID
            $0.spySearchTerm = searchTerm
            $0.spyPageNumber = pageNumber
            $0.spyPageSize = pageSize
            return try $0.mockSearchPagedOrdersResult.get()
        }
    }

    func loadPOSOrder(siteID: Int64, orderID: Int64) async throws -> Order {
        try state.withLock {
            $0.loadPOSOrderCalled = true
            $0.spySiteID = siteID
            $0.spyLoadPOSOrderID = orderID
            return try $0.loadPOSOrderResult.get()
        }
    }

    func loadPOSOrders(siteID: Int64, orderIDs: [Int64]) async throws -> [Order] {
        try state.withLock {
            $0.loadPOSOrdersByIDsCalled = true
            $0.spySiteID = siteID
            return try $0.loadPOSOrdersByIDsResult.get()
        }
    }

    func addPOSOrderNote(siteID: Int64,
                         orderID: Int64,
                         isCustomerNote: Bool,
                         note: String) async throws -> OrderNote {
        let error = state.withLock {
            $0.addPOSOrderNoteCalled = true
            $0.spySiteID = siteID
            $0.spyAddPOSOrderNoteOrderID = orderID
            $0.spyAddPOSOrderNoteIsCustomerNote = isCustomerNote
            $0.spyAddPOSOrderNoteText = note
            return $0.addPOSOrderNoteError
        }
        if let error {
            throw error
        }
        return OrderNote.fake()
    }
}
