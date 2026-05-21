import Foundation
import CocoaLumberjackSwift

public enum ProductsListTool {

    public static let name = "products_list"
    public static let maxIncludeIDs = 100

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        List, search, or look up product entities. Returns top-level products by default. \
        Pass `parent_id: N` to list variations of variable product N. Pass `ids: [N, M, ...]` \
        to fetch specific entities by id. Pass `search: "..."` to name-match. Filters: \
        `stock_status`, `status`. Each row has `id`, `kind` ("product" or "variation"), \
        `parent_id` (for variations), `name`, `sku`, `price`, `stock_status`, plus \
        product-only fields like `type` and `variations_count`. \
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
                    "description": .string("Filter by exact stock status.")
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
        let orderby: String?
        let order: String?
        let page: Int?
        let perPage: Int?

        enum CodingKeys: String, CodingKey {
            case search, status, category, sku, ids, orderby, order, page
            case parentID = "parent_id"
            case stockStatus = "stock_status"
            case perPage = "per_page"
        }
    }

    private enum AllowedListValues {
        static let arguments: Set<String> = [
            "search", "status", "category", "sku", "ids", "parent_id", "stock_status",
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
}
