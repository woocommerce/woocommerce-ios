import Foundation

/// `fetch` returns the full entity for the renderer; `summarize` returns the
/// compact projection the model is allowed to see. Letting the model see the
/// entity directly is what causes the 50k-token list-read pathology.
public struct CardFamily: Sendable {
    public let id: CardFamilyID
    private let pathStrategy: PathStrategy
    private let summaryKeys: [String]
    private let extraSummary: (@Sendable (AnyCodableJSON) -> [String: AnyCodableJSON])?
    private let checkTrash: Bool

    enum PathStrategy: Sendable {
        case directByID(prefix: String)
        case includeQuery(path: String)
    }

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

    public func fetch(id: Int64, client: WCRESTClient) async -> CardFetchOutcome {
        switch pathStrategy {
        case .directByID(let prefix):
            let response = await client.request(method: "GET",
                                                path: "\(prefix)\(id)",
                                                query: nil,
                                                body: nil,
                                                headers: nil)
            guard HTTPStatusClassification.isSuccess(response.statusCode) else {
                return .rejected(CardFetchOutcome.rejection(forStatusCode: response.statusCode))
            }
            guard let entity = RESTResponseParsing.decodeJSON(response.data) else {
                return .rejected(.internalError)
            }
            let pruned = RESTPayloadPruning.prune(entity)
            // WC returns `status: "trash"` with a 200 for soft-deleted rows; treat
            // as stale rather than render a card the merchant cannot act on.
            if checkTrash, RESTResponseParsing.stringField(pruned, "status") == "trash" {
                return .rejected(.staleReference)
            }
            return .found(pruned)
        case .includeQuery(let path):
            let response = await client.request(method: "GET",
                                                path: path,
                                                query: ["include": String(id)],
                                                body: nil,
                                                headers: nil)
            guard HTTPStatusClassification.isSuccess(response.statusCode) else {
                return .rejected(CardFetchOutcome.rejection(forStatusCode: response.statusCode))
            }
            guard let payload = RESTResponseParsing.decodeJSON(response.data),
                  let rows = RESTResponseParsing.arrayItems(payload) else {
                return .rejected(.internalError)
            }
            guard let row = rows.first else {
                return .rejected(.notFound)
            }
            return .found(RESTPayloadPruning.prune(row))
        }
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
        pathStrategy: .directByID(prefix: "wc/v3/orders/"),
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
        pathStrategy: .directByID(prefix: "wc/v3/products/"),
        summaryKeys: ["id", "name", "sku", "price", "stock_status"],
        checkTrash: true
    )

    /// `customers/{id}` requires `manage_woocommerce`, which most shop_manager
    /// roles lack; `customers?include=` works under `read_customers` and is
    /// the universal path even for permissive roles.
    public static let customer = CardFamily(
        id: .customer,
        pathStrategy: .includeQuery(path: "wc/v3/customers"),
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
