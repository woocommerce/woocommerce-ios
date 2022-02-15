import Foundation

/// Order: Remote Endpoints
///
public class OrdersRemote: Remote {

    /// Retrieves all of the `Orders` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote orders.
    ///     - statuses: Filters the Orders by the specified Status, if any.
    ///     - after: If given, limit response to orders published after a given compliant date.  Passing a local date is fine. This
    ///               method will convert it to UTC ISO 8601 before calling the REST API.
    ///     - before: If given, limit response to resources published before a given compliant date.. Passing a local date is fine. This
    ///               method will convert it to UTC ISO 8601 before calling the REST API.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of Orders to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllOrders(for siteID: Int64,
                              statuses: [String]? = nil,
                              after: Date? = nil,
                              before: Date? = nil,
                              pageNumber: Int = Defaults.pageNumber,
                              pageSize: Int = Defaults.pageSize,
                              completion: @escaping (Result<[Order], Error>) -> Void) {
        let utcDateFormatter = DateFormatter.Defaults.iso8601

        let statusesString: String? = statuses?.isEmpty == true ? Defaults.statusAny : statuses?.joined(separator: ",")
        let parameters: [String: Any] = {
            var parameters = [
                ParameterKeys.page: String(pageNumber),
                ParameterKeys.perPage: String(pageSize),
                ParameterKeys.statusKey: statusesString ?? Defaults.statusAny,
                ParameterKeys.fields: ParameterValues.listFieldValues,
            ]

            if let after = after {
                parameters[ParameterKeys.after] = utcDateFormatter.string(from: after)
            }
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
            ParameterKeys.fields: ParameterValues.singleOrderFieldValues
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
            ParameterKeys.fields: ParameterValues.listFieldValues
        ]

        let path = Constants.ordersPath
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = OrderListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Creates an order using the specified fields of a given order
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - order: Order to be created.
    ///     - fields: Fields of the order to be created.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createOrder(siteID: Int64, order: Order, fields: [CreateOrderField], completion: @escaping (Result<Order, Error>) -> Void) {
        do {
            let path = Constants.ordersPath
            let mapper = OrderMapper(siteID: siteID)
            let parameters: [String: Any] = try {
                try fields.reduce(into: [:]) { params, field in
                    switch field {
                    case .feeLines:
                        params[Order.CodingKeys.feeLines.rawValue] = try order.fees.compactMap { try $0.toDictionary() }
                    case .status:
                        params[Order.CodingKeys.status.rawValue] = order.status.rawValue
                    case .items:
                        params[Order.CodingKeys.items.rawValue] = order.items.map { item in
                            [OrderItem.CodingKeys.productID.rawValue: item.variationID != 0 ? item.variationID : item.productID,
                             OrderItem.CodingKeys.quantity.rawValue: Int64(truncating: item.quantity as NSDecimalNumber)]
                        }
                    case .billingAddress:
                        if let billingAddress = order.billingAddress {
                            params[Order.CodingKeys.billingAddress.rawValue] = try billingAddress.toDictionary()
                        }
                    case .shippingAddress:
                        if let shippingAddress = order.shippingAddress {
                            params[Order.CodingKeys.shippingAddress.rawValue] = try shippingAddress.toDictionary()
                        }
                    case .shippingLines:
                        params[Order.CodingKeys.shippingLines.rawValue] = try order.shippingLines.compactMap { try $0.toDictionary() }
                    }
                }
            }()

            let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
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

    /// Updates the specified fields of a given order.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - order: Order to be updated.
    ///     - fields: Fields from the order to be updated.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateOrder(from siteID: Int64, order: Order, fields: [UpdateOrderField], completion: @escaping (Result<Order, Error>) -> Void) {
        do {
            let path = "\(Constants.ordersPath)/\(order.orderID)"
            let mapper = OrderMapper(siteID: siteID)
            let parameters: [String: Any] = try {
                try fields.reduce(into: [:]) { params, field in
                    switch field {
                    case .customerNote:
                        params[Order.CodingKeys.customerNote.rawValue] = order.customerNote
                    case .shippingAddress:
                        let shippingAddressEncoded = try order.shippingAddress?.toDictionary()
                        params[Order.CodingKeys.shippingAddress.rawValue] = shippingAddressEncoded
                    case .billingAddress:
                        let billingAddressEncoded = try order.billingAddress?.toDictionary()
                        params[Order.CodingKeys.billingAddress.rawValue] = billingAddressEncoded
                    case .fees:
                        let feesEncoded = try order.fees.map { try $0.toDictionary() }
                        params[Order.CodingKeys.feeLines.rawValue] = feesEncoded
                    case .shippingLines:
                        let shippingEncoded = try order.shippingLines.map { try $0.toDictionary() }
                        params[Order.CodingKeys.shippingLines.rawValue] = shippingEncoded
                    }
                }
            }()

            let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
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
        static let after: String            = "after"
        static let before: String           = "before"
    }

    enum ParameterValues {
        // Same as singleOrderFieldValues except we exclude the line_items and shipping fields
        static let listFieldValues: String = commonOrderFieldValues.joined(separator: ",")
        static let singleOrderFieldValues: String = (commonOrderFieldValues + singleOrderExtraFieldValues).joined(separator: ",")
        private static let commonOrderFieldValues = [
            "id", "parent_id", "number", "status", "currency", "customer_id", "customer_note", "date_created_gmt", "date_modified_gmt", "date_paid_gmt",
            "discount_total", "discount_tax", "shipping_total", "shipping_tax", "total", "total_tax", "payment_method", "payment_method_title",
            "billing", "coupon_lines", "shipping_lines", "refunds", "fee_lines", "order_key", "tax_lines", "meta_data"
        ]
        // Use with caution. Any fields in here will be overwritten with empty values by
        // `Order+ReadOnlyConvertible.swift: Order.update(with:)` when the list of orders is fetched.
        // See p91TBi-7yL-p2 for discussion.
        private static let singleOrderExtraFieldValues = [
            "line_items", "shipping"
        ]
    }

    /// Order fields supported for update
    ///
    enum UpdateOrderField {
        case customerNote
        case shippingAddress
        case billingAddress
        case fees
        case shippingLines
    }

    /// Order fields supported for create
    ///
    enum CreateOrderField {
        case feeLines
        case status
        case items
        case billingAddress
        case shippingAddress
        case shippingLines
    }
}
