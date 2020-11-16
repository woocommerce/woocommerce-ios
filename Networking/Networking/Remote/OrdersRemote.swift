import Foundation

/// Order: Remote Endpoints
///
public class OrdersRemote: Remote {

    /// Retrieves all of the `Orders` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote orders.
    ///     - status: Filters the Orders by the specified Status, if any.
    ///     - before: If given, exclude orders created before this date/time. Passing a local date is fine. This
    ///               method will convert it to UTC ISO 8601 before calling the REST API.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of Orders to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllOrders(for siteID: Int64,
                              statusKey: String? = nil,
                              before: Date? = nil,
                              pageNumber: Int = Defaults.pageNumber,
                              pageSize: Int = Defaults.pageSize,
                              completion: @escaping (Result<[Order], Error>) -> Void) {
        let utcDateFormatter = DateFormatter.Defaults.iso8601

        let parameters: [String: Any] = {
            var parameters = [
                ParameterKeys.page: String(pageNumber),
                ParameterKeys.perPage: String(pageSize),
                ParameterKeys.statusKey: statusKey ?? Defaults.statusAny,
                ParameterKeys.fields: ParameterValues.fieldValues,
            ]

            if let before = before {
                parameters[ParameterKeys.before] = utcDateFormatter.string(from: before)
            }

            return parameters
        }()

        let path = Constants.ordersPath
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = OrderListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a specific `Order`
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - orderID: Identifier of the Order.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadOrder(for siteID: Int64, orderID: Int64, completion: @escaping (Order?, Error?) -> Void) {
        let parameters = [
            ParameterKeys.fields: ParameterValues.fieldValues
        ]

        let path = "\(Constants.ordersPath)/\(orderID)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = OrderMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves the notes for a specific `Order`
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - orderID: Identifier of the Order.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadOrderNotes(for siteID: Int64, orderID: Int64, completion: @escaping ([OrderNote]?, Error?) -> Void) {
        let path = "\(Constants.ordersPath)/\(orderID)/\(Constants.notesPath)/"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = OrderNotesMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves all of the `Orders` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote orders.
    ///     - keyword: Search string that should be matched by the orders.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of Orders to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func searchOrders(for siteID: Int64,
                             keyword: String,
                             pageNumber: Int = Defaults.pageNumber,
                             pageSize: Int = Defaults.pageSize,
                             completion: @escaping ([Order]?, Error?) -> Void) {
        let parameters = [
            ParameterKeys.keyword: keyword,
            ParameterKeys.page: String(pageNumber),
            ParameterKeys.perPage: String(pageSize),
            ParameterKeys.statusKey: Defaults.statusAny,
            ParameterKeys.fields: ParameterValues.fieldValues
        ]

        let path = Constants.ordersPath
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = OrderListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates the `OrderStatus` of a given Order.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - orderID: Identifier of the Order to be updated.
    ///     - status: New Status to be set.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateOrder(from siteID: Int64, orderID: Int64, statusKey: OrderStatusEnum, completion: @escaping (Order?, Error?) -> Void) {
        let path = "\(Constants.ordersPath)/" + String(orderID)
        let parameters = [ParameterKeys.statusKey: statusKey.rawValue]
        let mapper = OrderMapper(siteID: siteID)

        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Adds an order note to a specific Order.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - orderID: Identifier of the Order to be updated.
    ///     - isCustomerNote: if true, the note will be shown to customers and they will be notified.
    ///                       if false, the note will be for admin reference only. Default is false.
    ///     - note: The note to be posted.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func addOrderNote(for siteID: Int64, orderID: Int64, isCustomerNote: Bool, with note: String, completion: @escaping (OrderNote?, Error?) -> Void) {
        let path = "\(Constants.ordersPath)/" + String(orderID) + "/" + "\(Constants.notesPath)"
        let parameters = [ParameterKeys.note: note,
                          ParameterKeys.customerNote: String(isCustomerNote),
                          ParameterKeys.addedByUser: String(true)] // This will always be true when creating notes in-app
        let mapper = OrderNoteMapper()

        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves the number of Orders available for all order statuses
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch the order count.
    ///     - ststusKey: the order status slug
    ///     - completion: Closure to be executed upon completion.
    ///
    public func countOrders(for siteID: Int64, statusKey: String, completion: @escaping (OrderCount?, Error?) -> Void) {
        let parameters = [ParameterKeys.statusKey: statusKey]

        let mapper = OrderCountMapper(siteID: siteID)

        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: Constants.totalsPath, parameters: parameters)
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
public extension OrdersRemote {
    enum Defaults {
        public static let pageSize: Int     = 25
        public static let pageNumber: Int   = 1
        public static let statusAny: String = "any"
    }

    private enum Constants {
        static let ordersPath: String       = "orders"
        static let notesPath: String        = "notes"
        static let totalsPath: String       = "reports/orders/totals"
    }

    private enum ParameterKeys {
        static let addedByUser: String      = "added_by_user"
        static let customerNote: String     = "customer_note"
        static let keyword: String          = "search"
        static let note: String             = "note"
        static let page: String             = "page"
        static let perPage: String          = "per_page"
        static let statusKey: String        = "status"
        static let fields: String           = "_fields"
        static let before: String           = "before"
    }

    enum ParameterValues {
        static let fieldValues: String = """
            id,parent_id,number,status,currency,customer_id,customer_note,date_created_gmt,date_modified_gmt,date_paid_gmt,\
            discount_total,discount_tax,shipping_total,shipping_tax,total,total_tax,payment_method,payment_method_title,line_items,shipping,\
            billing,coupon_lines,shipping_lines,refunds
            """
    }
}
