import Foundation
import CocoaLumberjackSwift

public enum ProductsListTool {

    public static let name = "products_list"
    public static let maxIncludeIDs = 100
    /// Fallback threshold used only when the wc-analytics stock report is unavailable
    /// (older WC installs) and we scan paginated /products as a heuristic.
    static let lowStockThreshold = 10
    /// Bounds the heuristic multi-page scan that runs when wc-analytics is unavailable.
    static let lowInStockMaxPagesScanned = 3

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        List, search, or look up product entities. Returns top-level products by default. \
        Pass `parent_id: N` to list variations of variable product N. Pass `ids: [N, M, ...]` \
        to fetch specific entities by id. Pass `search: "..."` to name-match. Filters: \
        `stock_status`, `status`, `low_in_stock` (returns products that meet WooCommerce's \
        low-stock criteria - per-product `low_stock_amount` override or site-wide \
        `woocommerce_notify_low_stock_amount`), `min_price`, `max_price`. Each row has `id`, \
        `kind` ("product" or "variation"), `parent_id` (for variations), `name`, `sku`, \
        `price`, `stock_status`, plus product-only fields like `type` and `variations_count`. \
        Each row also carries a `target` object {kind, id, parent_id?} you can pass directly \
        to products_update.updates[].target without interpreting the row shape yourself. \
        After calling, pass returned ids to `show_cards` to render rather than re-fetching. \
        Do not use this tool to resolve a pronoun, ordinal, or qualifier when prior product \
        rows/cards are already in context; use the prior id with `show_cards`. If a search \
        returns no matches, do not retry with synonyms or broader terms - say no match was found.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "search": .object([
                    "type": .string("string"),
                    "description": .string("Free-text search across product name and content.")
                ]),
                "status": .object([
                    "type": .string("string"),
                    "enum": .array(AllowedListValues.statuses.sorted().map { .string($0) }),
                    "description": .string("Publication status; default 'any'.")
                ]),
                "category": .object([
                    "type": .string("integer"),
                    "description": .string("Category ID filter.")
                ]),
                "sku": .object([
                    "type": .string("string"),
                    "description": .string("Exact SKU lookup.")
                ]),
                "ids": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("integer")]),
                    "description": .string("Specific IDs to fetch. Top-level product ids by default. "
                        + "To fetch variations by id, also pass `parent_id` so the lookup is scoped "
                        + "to that variable product. Max \(maxIncludeIDs).")
                ]),
                "parent_id": .object([
                    "type": .string("integer"),
                    "description": .string("Set to list variations of a variable product with this id.")
                ]),
                "stock_status": .object([
                    "type": .string("string"),
                    "enum": .array(AllowedListValues.stockStatuses.sorted().map { .string($0) }),
                    "description": .string("Filter by exact stock status. For 'low stock' or "
                        + "'running low' queries use `low_in_stock` instead.")
                ]),
                "low_in_stock": .object([
                    "type": .string("boolean"),
                    "description": .string(
                        "When true, returns products that meet WooCommerce's low-stock criteria "
                        + "(per-product `low_stock_amount` or site-wide threshold). "
                        + "Use for 'low stock' or 'running low' queries."
                    )
                ]),
                "min_price": .object([
                    "type": .string("string"),
                    "description": .string("Lower bound on price. Decimal string, e.g. \"10.00\".")
                ]),
                "max_price": .object([
                    "type": .string("string"),
                    "description": .string("Upper bound on price. Decimal string, e.g. \"49.99\".")
                ]),
                "orderby": .object([
                    "type": .string("string"),
                    "enum": .array(AllowedListValues.orderBy.sorted().map { .string($0) }),
                    "description": .string("Sort key; default 'date'. Use 'popularity' for top / best-selling products.")
                ]),
                "order": .object([
                    "type": .string("string"),
                    "enum": .array(AllowedListValues.order.sorted().map { .string($0) }),
                    "description": .string("Sort direction; default 'desc'.")
                ]),
                "page": .object([
                    "type": .string("integer"),
                    "description": .string("1-based page number; default 1.")
                ]),
                "per_page": .object([
                    "type": .string("integer"),
                    "description": .string("Max items; clamped 1-50, default 20.")
                ])
            ])
        ]),
        safetyLevel: .safe
    )

    struct Args: Decodable, Sendable {
        let search: String?
        let status: String?
        let category: Int?
        let sku: String?
        let ids: [Int]?
        let parentID: Int?
        let stockStatus: String?
        let lowInStock: Bool?
        let minPrice: String?
        let maxPrice: String?
        let orderby: String?
        let order: String?
        let page: Int?
        let perPage: Int?

        enum CodingKeys: String, CodingKey {
            case search, status, category, sku, ids, orderby, order, page
            case parentID = "parent_id"
            case stockStatus = "stock_status"
            case lowInStock = "low_in_stock"
            case minPrice = "min_price"
            case maxPrice = "max_price"
            case perPage = "per_page"
        }

        init(search: String?, status: String?, category: Int?, sku: String?, ids: [Int]?,
             parentID: Int?, stockStatus: String?, lowInStock: Bool?, minPrice: String?,
             maxPrice: String?, orderby: String?, order: String?, page: Int?, perPage: Int?) {
            self.search = search; self.status = status; self.category = category; self.sku = sku
            self.ids = ids; self.parentID = parentID; self.stockStatus = stockStatus
            self.lowInStock = lowInStock; self.minPrice = minPrice; self.maxPrice = maxPrice
            self.orderby = orderby; self.order = order; self.page = page; self.perPage = perPage
        }

        func copy(page: Int) -> Args {
            Args(search: search, status: status, category: category, sku: sku, ids: ids,
                 parentID: parentID, stockStatus: stockStatus, lowInStock: lowInStock,
                 minPrice: minPrice, maxPrice: maxPrice, orderby: orderby, order: order,
                 page: page, perPage: perPage)
        }
    }

    private enum AllowedListValues {
        static let arguments: Set<String> = [
            "search", "status", "category", "sku", "ids", "parent_id", "stock_status",
            "low_in_stock", "min_price", "max_price",
            "orderby", "order", "page", "per_page"
        ]
        static let statuses: Set<String> = ["any", "draft", "pending", "private", "publish"]
        static let stockStatuses: Set<String> = ["instock", "outofstock", "onbackorder"]
        static let orderBy: Set<String> = ["date", "title", "popularity"]
        static let order: Set<String> = ["asc", "desc"]
    }

    static func query(from args: Args) -> [String: String] {
        var query: [String: String] = [
            "per_page": String(RESTToolDispatch.clampedPerPage(args.perPage))
        ]
        if args.ids?.isEmpty == false {
            query["orderby"] = "include"
        } else {
            query["orderby"] = args.orderby ?? "date"
            query["order"] = args.order ?? "desc"
        }
        if let status = args.status, status != "any" { query["status"] = status }
        if let search = args.search?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
            query["search"] = search
        }
        if let category = args.category { query["category"] = String(category) }
        if let sku = args.sku?.trimmingCharacters(in: .whitespacesAndNewlines), !sku.isEmpty {
            query["sku"] = sku
        }
        if let ids = args.ids, !ids.isEmpty {
            query["include"] = ids.map(String.init).joined(separator: ",")
        }
        if let stockStatus = args.stockStatus?.trimmingCharacters(in: .whitespacesAndNewlines),
           !stockStatus.isEmpty {
            query["stock_status"] = stockStatus
        }
        if let minPrice = args.minPrice?.trimmingCharacters(in: .whitespacesAndNewlines),
           !minPrice.isEmpty {
            query["min_price"] = minPrice
        }
        if let maxPrice = args.maxPrice?.trimmingCharacters(in: .whitespacesAndNewlines),
           !maxPrice.isEmpty {
            query["max_price"] = maxPrice
        }
        if let page = args.page, page > 1 { query["page"] = String(page) }
        return query
    }

    static let allowedArguments: Set<String> = AllowedListValues.arguments

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        if let failed = ToolArgumentValidation.validate(arguments: arguments,
                                                        allowed: AllowedListValues.arguments,
                                                        toolName: name) {
            return .failed(failed)
        }
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        if let failed = validateCombinations(args) {
            return .failed(failed)
        }
        let perPage = RESTToolDispatch.clampedPerPage(args.perPage)
        let path = args.parentID.map { "wc/v3/products/\($0)/variations" } ?? "wc/v3/products"
        if args.lowInStock == true {
            // wc-analytics' stock report is authoritative for low-stock and respects
            // per-product overrides; fall back to a heuristic scan for older WC installs.
            if args.parentID == nil,
               let result = await LowInStockReportRunner(client: client).run(args: args, perPage: perPage) {
                return result
            }
            return await scanLowInStockHeuristic(args: args, path: path, perPage: perPage, client: client)
        }
        return await fetchAndSummarize(args: args, path: path, perPage: perPage, client: client)
    }

    private static func fetchAndSummarize(args: Args,
                                          path: String,
                                          perPage: Int,
                                          client: WCRESTClient) async -> ToolResult {
        let response = await client.request(method: "GET",
                                            path: path,
                                            query: query(from: args),
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failed(RESTToolDispatch.failed(from: response, toolName: name))
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data),
              let rawRows = RESTResponseParsing.arrayItems(payload) else {
            return .failed(.init(toolName: name,
                                 kind: .toolFailed,
                                 reason: "expected JSON array"))
        }
        let canLoadMore = canLoadMore(rowsCount: rawRows.count, perPage: perPage, args: args)
        let kind: ProductsListSummary.RowKind = args.parentID == nil ? .product : .variation
        let summary = ProductsListSummary.make(from: rawRows, canLoadMore: canLoadMore, kind: kind)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }

    /// Narrows enriched low-stock rows by the merchant's other filters. The stock report ignores
    /// non-stock parameters, so this is the only place those filters take effect for this path.
    static func applyLowInStockPostFilters(rows: [AnyCodableJSON],
                                           args: Args,
                                           allowCategoryFilter: Bool) -> [AnyCodableJSON] {
        let matcher = ProductsRowMatcher(args: args, allowCategoryFilter: allowCategoryFilter)
        return rows.filter(matcher.matches)
    }

    private static func scanLowInStockHeuristic(args: Args,
                                                path: String,
                                                perPage: Int,
                                                client: WCRESTClient) async -> ToolResult {
        var collected: [AnyCodableJSON] = []
        let startPage = max(1, args.page ?? 1)
        var lastPageHadFullWindow = true
        for offset in 0..<lowInStockMaxPagesScanned {
            let pageArgs = args.copy(page: startPage + offset)
            let response = await client.request(method: "GET",
                                                path: path,
                                                query: query(from: pageArgs),
                                                body: nil)
            guard HTTPStatusClassification.isSuccess(response.statusCode) else {
                return .failed(RESTToolDispatch.failed(from: response, toolName: name))
            }
            guard let payload = RESTResponseParsing.decodeJSON(response.data),
                  let rawRows = RESTResponseParsing.arrayItems(payload) else {
                return .failed(.init(toolName: name, kind: .toolFailed, reason: "expected JSON array"))
            }
            lastPageHadFullWindow = rawRows.count >= perPage
            collected.append(contentsOf: rawRows.filter(isLowInStock))
            if collected.count >= perPage { break }
            if !lastPageHadFullWindow { break }
        }
        let rows = Array(collected.prefix(perPage))
        // Source pagination still full means more pages plausibly exist, regardless of
        // whether the response window filled - low-stock matches are often sparse.
        let canLoadMore = lastPageHadFullWindow
        let kind: ProductsListSummary.RowKind = args.parentID == nil ? .product : .variation
        let summary = ProductsListSummary.make(from: rows, canLoadMore: canLoadMore, kind: kind)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }

    private static func validateCombinations(_ args: Args) -> ToolResult.Failed? {
        if let ids = args.ids {
            if ids.isEmpty {
                return failure("ids must contain at least one entity ID.")
            }
            if ids.count > maxIncludeIDs {
                return failure("ids can contain at most \(maxIncludeIDs) entity IDs.")
            }
            let conflicts = (args.search != nil) || (args.sku != nil) || (args.orderby != nil) || (args.order != nil)
            if conflicts {
                return failure("ids cannot be combined with search, sku, orderby, or order.")
            }
        }
        if (args.orderby != nil || args.order != nil) && (args.search != nil || args.sku != nil) {
            return failure("orderby and order cannot be combined with search or sku.")
        }
        if let status = args.status, !AllowedListValues.statuses.contains(status) {
            return failure("'\(status)' is not an allowed status.")
        }
        if let stockStatus = args.stockStatus, !AllowedListValues.stockStatuses.contains(stockStatus) {
            return failure("'\(stockStatus)' is not an allowed stock_status.")
        }
        if let orderby = args.orderby, !AllowedListValues.orderBy.contains(orderby) {
            return failure("'\(orderby)' is not an allowed orderby.")
        }
        if let order = args.order, !AllowedListValues.order.contains(order) {
            return failure("'\(order)' is not an allowed order.")
        }
        return nil
    }

    private static func failure(_ reason: String) -> ToolResult.Failed {
        .init(toolName: name, kind: .invalidToolCall, reason: reason)
    }

    private static func canLoadMore(rowsCount: Int, perPage: Int, args: Args) -> Bool {
        if let ids = args.ids, !ids.isEmpty {
            let page = max(1, args.page ?? 1)
            return ids.count > page * perPage
        }
        return rowsCount >= perPage
    }

    private static func isLowInStock(_ row: AnyCodableJSON) -> Bool {
        guard case .object(let fields) = row, let raw = fields["stock_quantity"] else { return false }
        let quantity: Int
        switch raw {
        case .int(let value): quantity = Int(value)
        case .double(let value): quantity = Int(value)
        case .string(let value):
            guard let parsed = Int(value) else { return false }
            quantity = parsed
        default: return false
        }
        return quantity > 0 && quantity <= lowStockThreshold
    }
}
