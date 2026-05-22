import Foundation

/// `fetch` returns full entities for the renderer; `summarize` returns the
/// compact projection the model is allowed to see. Letting the model see the
/// entity directly is what causes the 50k-token list-read pathology.
struct CardFamily: Sendable {
    let id: CardFamilyID
    let pathStrategy: PathStrategy
    private let summaryKeys: [String]
    private let extraSummary: (@Sendable (AnyCodableJSON) -> [String: AnyCodableJSON])?
    private let checkTrash: Bool

    init(id: CardFamilyID,
         pathStrategy: PathStrategy,
         summaryKeys: [String],
         extraSummary: (@Sendable (AnyCodableJSON) -> [String: AnyCodableJSON])? = nil,
         checkTrash: Bool) {
        self.id = id
        self.pathStrategy = pathStrategy
        self.summaryKeys = summaryKeys
        self.extraSummary = extraSummary
        self.checkTrash = checkTrash
    }

    /// `batchedList` resolves up to 10 ids in a single call via WC `?include=`.
    /// `nestedByParent` requires a per-ref parent and fans out one HTTP call
    /// per ref because WC has no flat batched endpoint for variations.
    enum PathStrategy: Sendable {
        case batchedList(path: String)
        case nestedByParent(parentPathPrefix: String, childPath: String)
    }

    /// Single batched fetch per family using WC REST `include=` so 10 mixed-family
    /// references resolve in at most 3 HTTP calls instead of 10.
    func fetch(ids: [Int64], client: WCRESTClient) async -> [Int64: CardFetchOutcome] {
        guard ids.isEmpty == false else { return [:] }
        guard case .batchedList(let listPath) = pathStrategy else {
            return Dictionary(uniqueKeysWithValues: ids.map { ($0, .rejected(.internalError)) })
        }
        let includeValue = ids.map(String.init).joined(separator: ",")
        let response = await client.request(method: "GET",
                                            path: listPath,
                                            query: ["include": includeValue],
                                            body: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            let reason = CardRefRejectionReason.forStatusCode(response.statusCode)
            return Dictionary(uniqueKeysWithValues: ids.map { ($0, .rejected(reason)) })
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data),
              let rows = RESTResponseParsing.arrayItems(payload) else {
            return Dictionary(uniqueKeysWithValues: ids.map { ($0, .rejected(.internalError)) })
        }
        var keyed: [Int64: AnyCodableJSON] = [:]
        for row in rows {
            if let rowID = RESTResponseParsing.intField(row, "id") {
                keyed[rowID] = RESTPayloadPruning.prune(row)
            }
        }
        var outcomes: [Int64: CardFetchOutcome] = [:]
        for id in ids {
            guard let entity = keyed[id] else {
                outcomes[id] = .rejected(.notFound)
                continue
            }
            // WC returns `status: "trash"` with a 200 for soft-deleted rows; treat
            // as stale rather than render a card the merchant cannot act on.
            if checkTrash, RESTResponseParsing.stringField(entity, "status") == "trash" {
                outcomes[id] = .rejected(.staleReference)
                continue
            }
            outcomes[id] = .found(entity)
        }
        return outcomes
    }

    /// Per-ref fetch for nested resources. WC variations have no flat batched
    /// endpoint, so each (parent, child) pair runs in parallel via TaskGroup.
    func fetchNested(refs: [(id: Int64, parentID: Int64)],
                     client: WCRESTClient) async -> [Int64: CardFetchOutcome] {
        guard refs.isEmpty == false else { return [:] }
        guard case .nestedByParent(let parentPrefix, let childPath) = pathStrategy else {
            return Dictionary(uniqueKeysWithValues: refs.map { ($0.id, .rejected(.internalError)) })
        }
        return await withTaskGroup(of: (Int64, CardFetchOutcome).self) { group in
            for ref in refs {
                let path = "\(parentPrefix)\(ref.parentID)\(childPath)\(ref.id)"
                group.addTask {
                    let response = await client.request(method: "GET",
                                                        path: path,
                                                        query: nil,
                                                        body: nil)
                    return (ref.id, Self.outcome(for: response,
                                                 checkTrash: self.checkTrash,
                                                 injectParentID: ref.parentID))
                }
            }
            var outcomes: [Int64: CardFetchOutcome] = [:]
            for await (id, outcome) in group {
                outcomes[id] = outcome
            }
            return outcomes
        }
    }

    /// WC variation responses omit `parent_id`, but the renderer needs it for
    /// tap-through and the summary keys project it to the model. Inject the
    /// parent we already used to build the request URL so both consumers see it.
    private static func outcome(for response: WCRESTResponse,
                                checkTrash: Bool,
                                injectParentID: Int64? = nil) -> CardFetchOutcome {
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            return .rejected(CardRefRejectionReason.forStatusCode(response.statusCode))
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data),
              case .object = payload else {
            return .rejected(.internalError)
        }
        let pruned = RESTPayloadPruning.prune(payload)
        if checkTrash, RESTResponseParsing.stringField(pruned, "status") == "trash" {
            return .rejected(.staleReference)
        }
        guard let parentID = injectParentID, case .object(var dict) = pruned else {
            return .found(pruned)
        }
        if dict["parent_id"] == nil {
            dict["parent_id"] = .int(parentID)
        }
        return .found(.object(dict))
    }

    func summarize(_ entity: AnyCodableJSON) -> AnyCodableJSON {
        let projected = RESTResponseParsing.project(entity, keys: summaryKeys)
        guard let extraSummary else { return projected }
        guard case .object(var dict) = projected else { return projected }
        for (key, value) in extraSummary(entity) {
            dict[key] = value
        }
        return .object(dict)
    }

    static func forID(_ id: CardFamilyID) -> CardFamily {
        switch id {
        case .order: return .order
        case .product: return .product
        case .productVariation: return .productVariation
        case .customer: return .customer
        case .analyticsStats:
            preconditionFailure("CardFamily.forID(.analyticsStats) - resolver must dispatch analytics through AnalyticsCardFetch")
        }
    }

    static let order = CardFamily(
        id: .order,
        pathStrategy: .batchedList(path: "wc/v3/orders"),
        summaryKeys: ["id", "number", "status", "total", "currency", "date_created"],
        extraSummary: { entity in
            var extras: [String: AnyCodableJSON] = [:]
            if let billing = RESTResponseParsing.objectField(entity, "billing") {
                let first = RESTResponseParsing.stringField(billing, "first_name") ?? ""
                let last = RESTResponseParsing.stringField(billing, "last_name") ?? ""
                let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
                if !combined.isEmpty { extras["customer_name"] = .string(combined) }
            }
            if let title = RESTResponseParsing.stringField(entity, "payment_method_title"), !title.isEmpty {
                extras["payment_method_title"] = .string(title)
            }
            if let customerID = RESTResponseParsing.intField(entity, "customer_id"), customerID > 0 {
                extras["customer_id"] = .int(customerID)
            }
            let lineItems = RESTResponseParsing.arrayItems(
                RESTResponseParsing.objectField(entity, "line_items") ?? .null
            ) ?? []
            extras["line_items_count"] = .int(Int64(lineItems.count))
            extras["line_items"] = .array(lineItems.prefix(showCardsLineItemLimit).map(showCardsLineItem))
            return extras
        },
        checkTrash: true
    )

    private static let showCardsLineItemLimit = 7

    private static func showCardsLineItem(_ item: AnyCodableJSON) -> AnyCodableJSON {
        var out: [String: AnyCodableJSON] = [:]
        if let id = RESTResponseParsing.intField(item, "id") { out["id"] = .int(id) }
        if let name = RESTResponseParsing.stringField(item, "name") { out["name"] = .string(name) }
        if let qty = RESTResponseParsing.intField(item, "quantity") { out["quantity"] = .int(qty) }
        if let sku = RESTResponseParsing.stringField(item, "sku") { out["sku"] = .string(sku) }
        if let total = RESTResponseParsing.stringField(item, "total") { out["total"] = .string(total) }
        if let target = OrderSummary.lineItemTarget(from: item) { out["target"] = target }
        return .object(out)
    }

    static let product = CardFamily(
        id: .product,
        pathStrategy: .batchedList(path: "wc/v3/products"),
        summaryKeys: [
            "id", "name", "sku", "price", "stock_status",
            "type", "manage_stock", "on_sale", "stock_quantity",
            "variations_count"
        ],
        checkTrash: true
    )

    /// WC REST does not honor `?include={variation_id}` on `/wc/v3/products`,
    /// so variations must fetch through the nested per-parent path one at a
    /// time. `name` is the attribute option label ("Black"); `parent_id`
    /// surfaces so the model can link a variation back to its parent.
    static let productVariation = CardFamily(
        id: .productVariation,
        pathStrategy: .nestedByParent(parentPathPrefix: "wc/v3/products/", childPath: "/variations/"),
        summaryKeys: ["id", "name", "sku", "price", "stock_status", "parent_id"],
        checkTrash: true
    )

    /// `customers/{id}` requires `manage_woocommerce`, which most shop_manager
    /// roles lack; `customers?include=` works under `read_customers` and is
    /// the universal path even for permissive roles.
    static let customer = CardFamily(
        id: .customer,
        pathStrategy: .batchedList(path: "wc/v3/customers"),
        summaryKeys: ["id", "first_name", "last_name", "email", "orders_count"],
        checkTrash: false
    )
}

enum CardFetchOutcome: Sendable {
    case found(AnyCodableJSON)
    case rejected(CardRefRejectionReason)
}
