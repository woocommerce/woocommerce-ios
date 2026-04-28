import Foundation

public enum CustomersListTool {

    public static let name = "customers_list"

    public static func make() -> RESTTool {
        RESTTool(definition: definition, executor: execute)
    }

    private static let definition = AITool(
        name: name,
        description: """
        List customers, optionally filtered by keyword (matches name, email, \
        username) or email. Use `include=[id]` to look up one customer by ID; \
        the per-id customer endpoint requires manage_woocommerce so include \
        is the universal path.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "search": .object([
                    "type": .string("string"),
                    "description": .string("Free-text search across name, email, username.")
                ]),
                "email": .object([
                    "type": .string("string"),
                    "description": .string("Exact email lookup.")
                ]),
                "include": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("integer")]),
                    "description": .string("Specific customer IDs to include.")
                ]),
                "orderby": .object([
                    "type": .string("string"),
                    "enum": .array([.string("registered_date"), .string("name"),
                                    .string("id"), .string("email")]),
                    "description": .string("Sort key; default 'registered_date'.")
                ]),
                "order": .object([
                    "type": .string("string"),
                    "enum": .array([.string("asc"), .string("desc")]),
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
        ])
    )

    private struct Args: Decodable, Sendable {
        let search: String?
        let email: String?
        let include: [Int]?
        let orderby: String?
        let order: String?
        let page: Int?
        let perPage: Int?

        enum CodingKeys: String, CodingKey {
            case search, email, include, orderby, order, page
            case perPage = "per_page"
        }
    }

    private static func query(from args: Args) -> [String: String] {
        var query: [String: String] = [
            "orderby": args.orderby ?? "registered_date",
            "order": args.order ?? "desc",
            "per_page": String(RESTToolDispatch.clampedPerPage(args.perPage))
        ]
        if let search = args.search?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
            query["search"] = search
        }
        if let email = args.email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
            query["email"] = email
        }
        if let include = args.include, !include.isEmpty {
            query["include"] = include.map(String.init).joined(separator: ",")
        }
        if let page = args.page, page > 1 { query["page"] = String(page) }
        return query
    }

    private static let execute: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
        let args: Args
        switch RESTToolDispatch.decodeArguments(Args.self, from: arguments, toolName: name) {
        case .success(let value): args = value
        case .failure(let failed): return .failed(failed)
        }
        let response = await client.request(method: "GET",
                                            path: "wc/v3/customers",
                                            query: query(from: args),
                                            body: nil,
                                            headers: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .failed(RESTToolDispatch.failed(from: response, toolName: name))
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data),
              let rows = RESTResponseParsing.arrayItems(payload) else {
            return .failed(.init(toolName: name,
                                 kind: .toolFailed,
                                 reason: "expected JSON array"))
        }
        let summary = CustomersListSummary.make(from: rows)
        return .success(.init(toolName: name,
                              structured: LLMPayloadCap.capped(summary, toolName: name),
                              uiStructured: nil))
    }
}
