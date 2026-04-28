import Foundation

/// `fetch` returns full entities for the renderer; `summarize` returns the
/// compact projection the model is allowed to see. Letting the model see the
/// entity directly is what causes the 50k-token list-read pathology.
public struct CardFamily: Sendable {
    public let id: CardFamilyID
    private let listPath: String
    private let summaryKeys: [String]
    private let extraSummary: (@Sendable (AnyCodableJSON) -> [String: AnyCodableJSON])?
    private let checkTrash: Bool

    init(id: CardFamilyID,
         listPath: String,
         summaryKeys: [String],
         extraSummary: (@Sendable (AnyCodableJSON) -> [String: AnyCodableJSON])? = nil,
         checkTrash: Bool) {
        self.id = id
        self.listPath = listPath
        self.summaryKeys = summaryKeys
        self.extraSummary = extraSummary
        self.checkTrash = checkTrash
    }

    /// Single batched fetch per family using WC REST `include=` so 10 mixed-family
    /// references resolve in at most 3 HTTP calls instead of 10.
    public func fetch(ids: [Int64], client: WCRESTClient) async -> [Int64: CardFetchOutcome] {
        guard ids.isEmpty == false else { return [:] }
        let includeValue = ids.map(String.init).joined(separator: ",")
        let response = await client.request(method: "GET",
                                            path: listPath,
                                            query: ["include": includeValue],
                                            body: nil,
                                            headers: nil)
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            let reason = CardFetchOutcome.rejection(forStatusCode: response.statusCode)
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

    public func summarize(_ entity: AnyCodableJSON) -> AnyCodableJSON {
        let projected = RESTResponseParsing.project(entity, keys: summaryKeys)
        guard let extraSummary else { return projected }
        guard case .object(var dict) = projected else { return projected }
        for (key, value) in extraSummary(entity) {
            dict[key] = value
        }
        return .object(dict)
    }

    public static let order = CardFamily(
        id: .order,
        listPath: "wc/v3/orders",
        summaryKeys: ["id", "number", "status", "total", "currency", "date_created"],
        extraSummary: { entity in
            guard let billing = RESTResponseParsing.objectField(entity, "billing") else { return [:] }
            let first = RESTResponseParsing.stringField(billing, "first_name") ?? ""
            let last = RESTResponseParsing.stringField(billing, "last_name") ?? ""
            let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
            return combined.isEmpty ? [:] : ["customer_name": .string(combined)]
        },
        checkTrash: true
    )

    public static let product = CardFamily(
        id: .product,
        listPath: "wc/v3/products",
        summaryKeys: ["id", "name", "sku", "price", "stock_status"],
        checkTrash: true
    )

    /// `customers/{id}` requires `manage_woocommerce`, which most shop_manager
    /// roles lack; `customers?include=` works under `read_customers` and is
    /// the universal path even for permissive roles.
    public static let customer = CardFamily(
        id: .customer,
        listPath: "wc/v3/customers",
        summaryKeys: ["id", "first_name", "last_name", "email", "orders_count"],
        checkTrash: false
    )
}

public enum CardFetchOutcome: Sendable {
    case found(AnyCodableJSON)
    case rejected(CardRefRejectionReason)

    /// Default REST status to rejection mapping. Status-only cases route here;
    /// 2xx-with-trashed-payload routes through `.staleReference` directly.
    public static func rejection(forStatusCode statusCode: Int) -> CardRefRejectionReason {
        switch statusCode {
        case 401, 403: return .notPermitted
        case 404: return .notFound
        case 410: return .staleReference
        default: return .fetchFailed
        }
    }
}

public struct CardFamilyRegistry: Sendable {
    private let families: [CardFamilyID: CardFamily]

    public init(_ families: [CardFamily]) {
        self.families = Dictionary(uniqueKeysWithValues: families.map { ($0.id, $0) })
    }

    public static func defaultRegistry() -> CardFamilyRegistry {
        CardFamilyRegistry([.order, .product, .customer])
    }

    public func family(for id: CardFamilyID) -> CardFamily? {
        families[id]
    }
}
