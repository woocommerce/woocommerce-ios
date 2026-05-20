import Foundation

public protocol OrdersRemoteProtocol {
    func loadOrders(
        for siteID: Int64,
        orderIDs: [Int64]
    ) async throws -> [Order]
}

/// Order: Remote Endpoints
///
public class OrdersRemote: Remote, OrdersRemoteProtocol {
    /// The source of the order creation.
    public enum OrderCreationSource {
        case storeManagement
        case pointOfSale
    }

    /// Retrieves all of the `Orders` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote orders.
    ///     - statuses: Filters the Orders by the specified Status, if any.
    ///     - after: If given, limit response to orders published after a given compliant date. Passing a local date is fine. This
    ///               method will convert it to UTC ISO 8601 before calling the REST API.
    ///     - before: If given, limit response to resources published before a given compliant date.. Passing a local date is fine. This
    ///               method will convert it to UTC ISO 8601 before calling the REST API.
    ///     - modifiedAfter: If given, limit response to resources modified after a given compliant date. Passing a local date is fine.
    ///     This method will convert it to UTC ISO 8601 before calling the REST API.
    ///     - customerID: If given, limit response to orders placed by a customer.
    ///     - productID: If given, limit response to orders including the given product.
    ///     - createdVia: If given, limit response to orders created via the specified source (e.g. "pos-rest-api" for Point of Sale).
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of Orders to be retrieved per page.
    /// - Returns: Array of orders.
    /// - Throws: Network or parsing errors.
    ///
    public func loadAllOrders(for siteID: Int64,
                              statuses: [String]? = nil,
                              after: Date? = nil,
                              before: Date? = nil,
                              modifiedAfter: Date? = nil,
                              customerID: Int64? = nil,
                              productID: Int64? = nil,
                              createdVia: String? = nil,
                              pageNumber: Int = Defaults.pageNumber,
                              pageSize: Int = Defaults.pageSize) async throws -> [Order] {
        let utcDateFormatter = DateFormatter.Defaults.iso8601

        let statusesString: String? = statuses?.isEmpty == true ? Defaults.statusAny : statuses?.joined(separator: ",")
        let parameters: [String: Any] = {
            var parameters = [
                ParameterKeys.page: String(pageNumber),
                ParameterKeys.perPage: String(pageSize),
                ParameterKeys.statusKey: statusesString ?? Defaults.statusAny,
                ParameterKeys.usesGMTDates: true,
                ParameterKeys.fields: ParameterValues.fieldValues,
            ]

            if let after {
                parameters[ParameterKeys.after] = utcDateFormatter.string(from: after)
            }
            if let before {
                parameters[ParameterKeys.before] = utcDateFormatter.string(from: before)
            }
            if let modifiedAfter {
                parameters[ParameterKeys.modifiedAfter] = utcDateFormatter.string(from: modifiedAfter)
            }

            if let customerID {
                parameters[ParameterKeys.customer] = customerID
            }

            if let productID {
                parameters[ParameterKeys.product] = productID
            }

            if let createdVia {
                parameters[ParameterKeys.createdVia] = createdVia
            }

            return parameters
        }()

        let path = Constants.ordersPath
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = OrderListMapper(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
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
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = OrderMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves specific `Order`s.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote orders.
    ///     - orderIDs: The IDs of the orders to fetch.
    /// - Returns: Array of orders.
    /// - Throws: Network or parsing errors.
    ///
    public func loadOrders(
        for siteID: Int64,
        orderIDs: [Int64]
    ) async throws -> [Order] {
        guard !orderIDs.isEmpty else {
            return []
        }

        let parameters: [String: Any] = [
            ParameterKeys.include: Set(orderIDs).map(String.init).joined(separator: ","),
            ParameterKeys.perPage: String(orderIDs.count),
            ParameterKeys.fields: ParameterValues.fieldValues
        ]

        let path = Constants.ordersPath
        let request = JetpackRequest(
            wooApiVersion: .mark3,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true
        )
        let mapper = OrderListMapper(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
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
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
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
    /// - Returns: Array of orders matching the search criteria.
    /// - Throws: Network or parsing errors.
    ///
    public func searchOrders(for siteID: Int64,
                             keyword: String,
                             pageNumber: Int = Defaults.pageNumber,
                             pageSize: Int = Defaults.pageSize) async throws -> [Order] {
        let parameters = [
            ParameterKeys.keyword: keyword,
            ParameterKeys.page: String(pageNumber),
            ParameterKeys.perPage: String(pageSize),
            ParameterKeys.statusKey: Defaults.statusAny,
            ParameterKeys.fields: ParameterValues.fieldValues
        ]

        let path = Constants.ordersPath
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = OrderListMapper(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }

    /// Creates an order using the specified fields of a given order
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - order: Order to be created.
    ///     - giftCard: Optional gift card to apply to the order.
    ///     - fields: Fields of the order to be created.
    ///     - source: Source of the order creation.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createOrder(siteID: Int64,
                            order: Order,
                            giftCard: String?,
                            fields: [CreateOrderField],
                            source: OrderCreationSource = .storeManagement,
                            completion: @escaping (Result<Order, Error>) -> Void) {
        do {
            let path = Constants.ordersPath
            let mapper = OrderMapper(siteID: siteID)
            let parameters: [String: Any] = try {
                var params: [String: Any] = try fields.reduce(into: [:]) { params, field in
                    switch field {
                    case .feeLines:
                        params[Order.CodingKeys.feeLines.rawValue] = try order.fees.compactMap { try $0.toDictionary() }
                    case .status:
                        params[Order.CodingKeys.status.rawValue] = order.status.rawValue
                    case .items:
                        params[Order.CodingKeys.items.rawValue] = try order.items.map { try $0.toDictionary() }
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
                    case .couponLines:
                        params[Order.CodingKeys.couponLines.rawValue] = try order.coupons.compactMap { try $0.toDictionary() }
                    case .customerNote:
                        params[Order.CodingKeys.customerNote.rawValue] = order.customerNote
                    case .customerID:
                        params[Order.CodingKeys.customerID.rawValue] = order.customerID
                    case .currency:
                        params[Order.CodingKeys.currency.rawValue] = order.currency
                    }
                }

                // Custom amount isn't supported for gift cards.
                if let giftCard {
                    params[Order.CodingKeys.giftCards.rawValue] = try [[NestedFieldKeys.giftCardCode: giftCard].toDictionary()]
                }

                // Set source type to mark the order as created from mobile
                params[Order.CodingKeys.metadata.rawValue] = try [MetaData(metadataID: 0,
                                                                                key: OrderAttributionInfo.Keys.sourceType.rawValue,
                                                                                value: OrderAttributionInfo.Values.mobileAppSourceType).toDictionary()]

                if let createdViaValue = source.createdViaValue {
                    params[Order.CodingKeys.createdVia.rawValue] = createdViaValue
                }

                params[ParameterKeys.decimalPlaces] = OrdersRemote.Defaults.decimalPoints

                return params
            }()

            let request = JetpackRequest(wooApiVersion: .mark3,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
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
        let parameters = [
            ParameterKeys.statusKey: statusKey.rawValue,
            ParameterKeys.decimalPlaces: OrdersRemote.Defaults.decimalPoints
        ]
        let mapper = OrderMapper(siteID: siteID)

        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates the specified fields of a given order.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - order: Order to be updated.
    ///     - giftCard: Optional gift card to apply to the order.
    ///     - cashPaymentChangeDueAmount: Optional change due amount from cash payment.
    ///     - fields: Fields from the order to be updated.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateOrder(from siteID: Int64,
                            order: Order,
                            giftCard: String?,
                            cashPaymentChangeDueAmount: String? = nil,
                            fields: [UpdateOrderField],
                            completion: @escaping (Result<Order, Error>) -> Void) {
        do {
            let path = "\(Constants.ordersPath)/\(order.orderID)"
            let mapper = OrderMapper(siteID: siteID)
            let parameters: [String: Any] = try {
                var params: [String: Any] = try fields.reduce(into: [:]) { params, field in
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
                    case .couponLines:
                        let couponEncoded = try order.coupons.map { try $0.toDictionary() }
                        params[Order.CodingKeys.couponLines.rawValue] = couponEncoded
                    case .status:
                        params[Order.CodingKeys.status.rawValue] = order.status.rawValue
                    case .items:
                        params[Order.CodingKeys.items.rawValue] = try order.items.map { try $0.toDictionary() }
                    case .customerID:
                        params[Order.CodingKeys.customerID.rawValue] = order.customerID
                    case .paymentMethodID:
                        params[Order.CodingKeys.paymentMethodID.rawValue] = order.paymentMethodID
                    case .paymentMethodTitle:
                        params[Order.CodingKeys.paymentMethodTitle.rawValue] = order.paymentMethodTitle
                    }
                }

                // Custom amount isn't supported for gift cards.
                if let giftCard {
                    params[Order.CodingKeys.giftCards.rawValue] = try [[NestedFieldKeys.giftCardCode: giftCard].toDictionary()]
                }

                if let cashPaymentChangeDueAmount {
                    params[Order.CodingKeys.metadata.rawValue] = try [MetaData(metadataID: 0,
                                                                               key: NestedFieldKeys.cashPaymentChangeDueAmount,
                                                                               value: cashPaymentChangeDueAmount).toDictionary()]
                }

                // Add decimal places parameter for better precision
                params[ParameterKeys.decimalPlaces] = OrdersRemote.Defaults.decimalPoints

                return params
            }()

            let request = JetpackRequest(wooApiVersion: .mark3,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)
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

        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Deletes the given order.
    ///
    /// - Parameters:
    ///   - siteID: Site which hosts the Order.
    ///   - orderID: Identifier of the Order to be deleted.
    ///   - force: If true, the Order will be permanently deleted.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func deleteOrder(for siteID: Int64, orderID: Int64, force: Bool, completion: @escaping (Result<Order, Error>) -> Void) {
        let path = "\(Constants.ordersPath)/\(orderID)"
        let parameters = [ParameterKeys.force: String(force)]
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .delete,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = OrderMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves the date a specific `Order` was last modified.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Order.
    ///     - orderID: Identifier of the Order.
    /// - Returns:
    ///     Async result with a `Date` or an error
    ///
    public func fetchDateModified(for siteID: Int64, orderID: Int64) async throws -> Date {
        let parameters = [
            ParameterKeys.fields: ParameterValues.dateModifiedField
        ]

        let path = "\(Constants.ordersPath)/\(orderID)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = EntityDateModifiedMapper()

        return try await enqueue(request, mapper: mapper)
    }
}

extension OrdersRemote: POSOrdersRemoteProtocol {
    public func createPOSOrder(siteID: Int64, order: Order, fields: [CreateOrderField]) async throws -> Order {
        return try await withCheckedThrowingContinuation { continuation in
            createOrder(siteID: siteID, order: order, giftCard: nil, fields: fields, source: .pointOfSale) { result in
                switch result {
                case let .success(order):
                    continuation.resume(returning: order)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func updatePOSOrder(siteID: Int64, order: Order, cashPaymentChangeDueAmount: String? = nil, fields: [UpdateOrderField]) async throws -> Order {
        return try await withCheckedThrowingContinuation { continuation in
            updateOrder(from: siteID, order: order, giftCard: nil, cashPaymentChangeDueAmount: cashPaymentChangeDueAmount, fields: fields) { result in
                switch result {
                case let .success(order):
                    continuation.resume(returning: order)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func addPOSOrderNote(siteID: Int64,
                                orderID: Int64,
                                isCustomerNote: Bool,
                                note: String) async throws -> OrderNote {
        try await withCheckedThrowingContinuation { continuation in
            addOrderNote(for: siteID, orderID: orderID, isCustomerNote: isCustomerNote, with: note) { orderNote, error in
                if let orderNote {
                    continuation.resume(returning: orderNote)
                } else {
                    continuation.resume(throwing: error ?? POSOrdersRemoteError.addOrderNoteFailed)
                }
            }
        }
    }

    public func updatePOSOrderEmail(siteID: Int64, orderID: Int64, emailAddress: String) async throws {
        let parameters: [String: Any] = [
            "billing": [
                "email": emailAddress
            ]
        ]

        let path = "\(Constants.ordersPath)/\(orderID)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)

        try await enqueue(request)
    }

    public func loadPOSOrders(siteID: Int64, pageNumber: Int, pageSize: Int) async throws -> PagedItems<Order> {
        let parameters: [String: Any] = [
            ParameterKeys.page: String(pageNumber),
            ParameterKeys.perPage: String(pageSize),
            ParameterKeys.statusKey: Defaults.statusAny,
            ParameterKeys.usesGMTDates: true,
            ParameterKeys.fields: ParameterValues.fieldValues,
            ParameterKeys.createdVia: ParameterValues.posFilter
        ]

        let path = Constants.ordersPath
        let request = JetpackRequest(wooApiVersion: .mark3,
                                   method: .get,
                                   siteID: siteID,
                                   path: path,
                                   parameters: parameters,
                                   availableAsRESTRequest: true)
        let mapper = OrderListMapper(siteID: siteID)
        let (orders, responseHeaders) = try await enqueueWithResponseHeaders(request, mapper: mapper)
        return createPagedItems(items: orders, responseHeaders: responseHeaders, currentPageNumber: pageNumber)
    }

    public func searchPOSOrders(siteID: Int64, searchTerm: String, pageNumber: Int, pageSize: Int) async throws -> PagedItems<Order> {
        let parameters: [String: Any] = [
            ParameterKeys.keyword: searchTerm,
            ParameterKeys.page: String(pageNumber),
            ParameterKeys.perPage: String(pageSize),
            ParameterKeys.statusKey: Defaults.statusAny,
            ParameterKeys.usesGMTDates: true,
            ParameterKeys.fields: ParameterValues.fieldValues,
            ParameterKeys.createdVia: ParameterValues.posFilter
        ]
        let path = Constants.ordersPath
        let request = JetpackRequest(wooApiVersion: .mark3,
                                   method: .get,
                                   siteID: siteID,
                                   path: path,
                                   parameters: parameters,
                                   availableAsRESTRequest: true)
        let mapper = OrderListMapper(siteID: siteID)
        let (orders, responseHeaders) = try await enqueueWithResponseHeaders(request, mapper: mapper)
        return createPagedItems(items: orders, responseHeaders: responseHeaders, currentPageNumber: pageNumber)
    }
}


// MARK: - Constants!
//
public extension OrdersRemote {
    enum Defaults {
        public static let pageSize: Int = 25
        public static let pageNumber: Int = 1
        public static let decimalPoints: String = "8"
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
        static let include: String          = "include"
        static let note: String             = "note"
        static let page: String             = "page"
        static let perPage: String          = "per_page"
        static let statusKey: String        = "status"
        static let fields: String           = "_fields"
        static let after: String            = "after"
        static let before: String           = "before"
        static let force: String            = "force"
        static let modifiedAfter: String    = "modified_after"
        /// Whether to consider the published or modified dates in GMT. When `false`, the local date field is used for filtering orders.
        static let usesGMTDates: String     = "dates_are_gmt"
        static let customer = "customer"
        static let product = "product"
        static let createdVia = "created_via"
        static let decimalPlaces = "dp"
    }

    enum ParameterValues {
        static let fieldValues: String = commonOrderFieldValues.joined(separator: ",")
        private static let commonOrderFieldValues = [
            "id", "parent_id", "number", "status", "currency", "currency_symbol", "customer_id", "customer_note", "date_created_gmt", "date_modified_gmt",
            "date_paid_gmt", "discount_total", "discount_tax", "shipping_total", "shipping_tax", "total", "total_tax", "payment_method", "payment_method_title",
            "payment_url", "line_items", "shipping", "billing", "coupon_lines", "shipping_lines", "refunds", "fee_lines", "order_key", "tax_lines", "meta_data",
            "is_editable", "needs_payment", "needs_processing", "gift_cards", "created_via"
        ]
        static let dateModifiedField = "date_modified_gmt"
        static let posFilter = "pos-rest-api"
    }

    enum NestedFieldKeys {
        static let giftCardCode = "code"
        static let cashPaymentChangeDueAmount = "_cash_change_amount"
    }

    /// Order fields supported for update
    ///
    enum UpdateOrderField: CaseIterable {
        case customerNote
        case shippingAddress
        case billingAddress
        case fees
        case shippingLines
        case couponLines
        case items
        case status
        case customerID
        case paymentMethodID
        case paymentMethodTitle
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
        case couponLines
        case customerNote
        case customerID
        case currency
    }

    /// Loads a single order asynchronously for POS
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the order.
    ///   - orderID: ID of the order to load.
    /// - Returns: The loaded Order.
    /// - Throws: Network or parsing errors.
    func loadPOSOrder(siteID: Int64, orderID: Int64) async throws -> Order {
        let path = "\(Constants.ordersPath)/\(orderID)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                   method: .get,
                                   siteID: siteID,
                                   path: path,
                                   availableAsRESTRequest: true)
        let mapper = OrderMapper(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }

    public func loadPOSOrders(siteID: Int64, orderIDs: [Int64]) async throws -> [Order] {
        guard !orderIDs.isEmpty else { return [] }
        let parameters: [String: Any] = [
            ParameterKeys.include: Set(orderIDs).map(String.init).joined(separator: ","),
            ParameterKeys.perPage: String(orderIDs.count),
            ParameterKeys.fields: ParameterValues.fieldValues
        ]
        let path = Constants.ordersPath
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = OrderListMapper(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }
}

private extension OrdersRemote.OrderCreationSource {
    var createdViaValue: String? {
        switch self {
        case .storeManagement:
            return nil
        case .pointOfSale:
            return "pos-rest-api"
        }
    }
}
