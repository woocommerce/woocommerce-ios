import Foundation
import Networking



// MARK: - OrderAction: Defines all of the Actions supported by the OrderStore.
//
public enum OrderAction: Action {

    /// Searches orders that contain a given keyword.
    ///
    case searchOrders(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: (Error?) -> Void)

    /// Performs a dual fetch for the first pages of a filtered list and the all orders list.
    ///
    /// - Parameters:
    ///     - statusKey: The status to use for the filtered list. If this is not provided, only the
    ///                  all orders list will be fetched. See `OrderStatusEnum` for possible values.
    ///     - deleteAllBeforeSaving: If true, all the orders in the db will be deleted before any
    ///                  order from the fetch requests will be saved.
    ///     - before: Only include orders created before this date. The time zone of the `Date`
    ///               doesn't matter. It will be converted to UTC later.
    ///
    case fetchFilteredAndAllOrders(
        siteID: Int64,
        statusKey: String?,
        before: Date? = nil,
        deleteAllBeforeSaving: Bool,
        pageSize: Int,
        onCompletion: (TimeInterval, Error?) -> Void
    )

    /// Synchronizes the Orders matching the specified criteria.
    ///
    /// - Parameters:
    ///     - before: Only include orders created before this date. The time zone of the `Date`
    ///               doesn't matter. It will be converted to UTC later.
    ///
    case synchronizeOrders(siteID: Int64,
                           statusKey: String?,
                           before: Date? = nil,
                           pageNumber: Int,
                           pageSize: Int,
                           onCompletion: (TimeInterval, Error?) -> Void)

    /// Nukes all of the cached orders.
    ///
    case resetStoredOrders(onCompletion: () -> Void)

    /// Retrieves the specified OrderID.
    ///
    case retrieveOrder(siteID: Int64, orderID: Int64, onCompletion: (Order?, Error?) -> Void)

    /// Updates a given Order's Status.
    ///
    case updateOrderStatus(siteID: Int64, orderID: Int64, status: OrderStatusEnum, onCompletion: (Error?) -> Void)

    /// Updates the specified fields from an order.
    ///
    case updateOrder(siteID: Int64, order: Order, fields: [OrderUpdateField], onCompletion: (Result<Order, Error>) -> Void)

    /// Creates an order with the specified fields from a given order
    ///
    case createOrder(siteID: Int64, order: Order, fields: [CreateOrderField], onCompletion: (Result<Order, Error>) -> Void)
}
