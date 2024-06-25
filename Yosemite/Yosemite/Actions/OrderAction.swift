import Combine
import Foundation
import Networking



// MARK: - OrderAction: Defines all of the Actions supported by the OrderStore.
//
public enum OrderAction: Action {

    public enum OrdersStorageWriteStrategy {
        case save
        case deleteAllBeforeSaving
        case doNotSave
    }

    /// Searches orders that contain a given keyword.
    ///
    case searchOrders(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)

    /// Performs the fetch for the first pages of order list.
    ///
    /// - Parameters:
    ///     - statuses: The statuses to use for the filtered list. If this is not provided, only the
    ///                  all orders list will be fetched. See `OrderStatusEnum` for possible values.
    ///     - deleteAllBeforeSaving: If true, all the orders in the db will be deleted before any
    ///                  order from the fetch requests will be saved.
    ///     - after: Only include orders created after this date. The time zone of the `Date`
    ///               doesn't matter. It will be converted to UTC later.
    ///     - before: Only include orders created before this date. The time zone of the `Date`
    ///               doesn't matter. It will be converted to UTC later.
    ///     - modifiedAfter: Only include orders modified after this date. The time zone of the `Date`
    ///               doesn't matter. It will be converted to UTC later.
    ///     - customerID: Only include orders placed by the given customer.
    ///     - productID: Only include orders with `lineItems` including the given product.
    ///
    case fetchFilteredOrders(
        siteID: Int64,
        statuses: [String]?,
        after: Date? = nil,
        before: Date? = nil,
        modifiedAfter: Date? = nil,
        customerID: Int64? = nil,
        productID: Int64? = nil,
        writeStrategy: OrdersStorageWriteStrategy,
        pageSize: Int,
        onCompletion: (TimeInterval, Result<[Order], Error>) -> Void
    )

    /// Synchronizes the Orders matching the specified criteria.
    ///
    /// - Parameters:
    ///     - after: Only include orders created after this date. The time zone of the `Date`
    ///               doesn't matter. It will be converted to UTC later.
    ///     - before: Only include orders created before this date. The time zone of the `Date`
    ///               doesn't matter. It will be converted to UTC later.
    ///     - modifiedAfter: Only include orders modified after this date. The time zone of the `Date`
    ///               doesn't matter. It will be converted to UTC later.
    ///     - customerID: Only include orders placed by the given customer.
    ///     - productID: Only include orders with `lineItems` including the given product.
    ///
    case synchronizeOrders(siteID: Int64,
                           statuses: [String]?,
                           after: Date? = nil,
                           before: Date? = nil,
                           modifiedAfter: Date? = nil,
                           customerID: Int64? = nil,
                           productID: Int64? = nil,
                           pageNumber: Int,
                           pageSize: Int,
                           onCompletion: (TimeInterval, Error?) -> Void)

    /// Nukes all of the cached orders.
    ///
    case resetStoredOrders(onCompletion: () -> Void)

    /// Retrieves the specified OrderID.
    /// If the order exists in storage, it syncs the order's last modified date and if it is different, it syncs the order remotely.
    /// Otherwise, the order in storage is returned.
    ///
    case retrieveOrder(siteID: Int64, orderID: Int64, onCompletion: (Order?, Error?) -> Void)

    /// Retrieves the specified OrderID remotely.
    ///
    case retrieveOrderRemotely(siteID: Int64, orderID: Int64, onCompletion: (Result<Order, Error>) -> Void)

    /// Updates a given Order's Status.
    ///
    case updateOrderStatus(siteID: Int64, orderID: Int64, status: OrderStatusEnum, onCompletion: (Error?) -> Void)

    /// Updates the specified fields from an order.
    ///
    case updateOrder(siteID: Int64, order: Order, giftCard: String?, fields: [OrderUpdateField], onCompletion: (Result<Order, Error>) -> Void)

    /// Updates the specified fields from an order **optimistically**.
    ///
    case updateOrderOptimistically(siteID: Int64, order: Order, fields: [OrderUpdateField], onCompletion: (Result<Order, Error>) -> Void)

    /// Creates a simple payments order with a specific amount value and  tax status.
    ///
    case createSimplePaymentsOrder(siteID: Int64, status: OrderStatusEnum, amount: String, taxable: Bool, onCompletion: (Result<Order, Error>) -> Void)

    /// Creates a manual order with the provided order details.
    ///
    case createOrder(siteID: Int64, order: Order, giftCard: String?, onCompletion: (Result<Order, Error>) -> Void)

    /// Updates a simple payments order with the specified values.
    ///
    case updateSimplePaymentsOrder(siteID: Int64,
                                   orderID: Int64,
                                   feeID: Int64,
                                   status: OrderStatusEnum,
                                   amount: String,
                                   taxable: Bool,
                                   orderNote: String?,
                                   email: String?,
                                   onCompletion: (Result<Order, Error>) -> Void)

    /// Updates an order to be considered as paid locally, for use cases where the payment is captured in the
    /// app to prevent from multiple charging for the same order after subsequent failures (e.g. Interac in Canada).
    /// Internally, the order is marked with a paid date and the order status is changed to processing.
    ///
    case markOrderAsPaidLocally(siteID: Int64, orderID: Int64, datePaid: Date, onCompletion: (Result<Order, Error>) -> Void)

    /// Deletes a given order.
    ///
    case deleteOrder(siteID: Int64, order: Order, deletePermanently: Bool, onCompletion: (Result<Order, Error>) -> Void)

    /// Returns a publisher that emits inserted orders on the view storage context.
    ///
    case observeInsertedOrders(siteID: Int64, completion: (AnyPublisher<[Order], Never>) -> Void)

    /// Checks if the store already has any orders.
    ///
    case checkIfStoreHasOrders(siteID: Int64, onCompletion: (Result<Bool, Error>) -> Void)
}
