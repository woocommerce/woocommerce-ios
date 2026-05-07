import CocoaLumberjackSwift
import Foundation
import Storage
import Yosemite

public enum ShowCardsTool {

    public static let name = "show_cards"

    @MainActor
    public static func make(siteID: Int64,
                            storageManager: StorageManagerType,
                            dispatchAction: @escaping @MainActor @Sendable (Action) -> Void,
                            restClient: WCRESTClient) -> RESTTool {
        let dataSources: [CardFamily: any CardEntityDataSource] = [
            .order: AssistantOrdersDataSource(siteID: siteID, storageManager: storageManager, dispatchAction: dispatchAction),
            .product: AssistantProductsDataSource(siteID: siteID, storageManager: storageManager, dispatchAction: dispatchAction),
            .productVariation: AssistantProductVariationsDataSource(siteID: siteID, storageManager: storageManager, dispatchAction: dispatchAction),
            // Customer records are sparse in Yosemite storage, so customer cards stay REST-backed.
            .customer: AssistantCustomersDataSource(client: restClient)
        ]
        return make(dataSources: dataSources)
    }

    static func make(dataSources: [CardFamily: any CardEntityDataSource]) -> RESTTool {
        let resolver = CardReferenceResolver(dataSources: dataSources)
        let executor: @Sendable (String, WCRESTClient) async -> ToolResult = { arguments, client in
            let request: ShowCardsRequest
            switch RESTToolDispatch.decodeArguments(ShowCardsRequest.self, from: arguments, toolName: name) {
            case .success(let value): request = value
            case .failure(let failed): return .failed(failed)
            }
            let resolutions = await resolver.resolve(request.references, analyticsClient: client)
            return projection(of: resolutions, requested: request.references.count)
        }
        return RESTTool(definition: definition, executor: executor)
    }

    private static let definition = AITool(
        name: name,
        description: """
        Render rich cards for specific entities the user should see. Call \
        this whenever you would otherwise mention an order/product/customer \
        ID in prose. Supported families: order, product, product_variation, \
        customer, analytics_stats. `product_variation` references require both \
        `id` and `parent_id` (the parent product's id), and should be used only \
        for explicit variation-level questions about sizes, colors, options, or \
        known variation IDs. For broad product inventory lists, render product \
        references. Order/product/customer references need only `id`. Up to 10 \
        references per call. Prefer 1-5 for list-style answers; summarize the \
        rest in prose. A single call may mix families when the user asks for \
        different entity types. Cards render \
        the entity's full detail to the user, but the model-visible result \
        is a compact summary only. Model-visible fields per family: order \
        has id, number, status, total, currency, date_created, customer_name; \
        product has id, name, sku, price, stock_status; product_variation \
        adds parent_id; customer has id, first_name, last_name, email, \
        orders_count. For any other field (line items, payment method, \
        billing/shipping address, phone, recent-order details, etc.) use \
        the appropriate get or list tool from the catalog. Cards rendered \
        in this turn remain referenced; reuse their ids in follow-up tool \
        calls. After a successful `analytics_revenue` or `analytics_orders` \
        call, call this tool with family `analytics_stats` and an id using \
        the same after, before, and interval values to render the analytics \
        card. Use the same currency value when the analytics call had one; \
        otherwise use `currency:none`. The synthetic analytics id format is \
        described on the `id` property.
        """,
        parametersSchema: .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "required": .array([.string("references")]),
            "properties": .object([
                "references": .object([
                    "type": .string("array"),
                    "minItems": .int(1),
                    "maxItems": .int(10),
                    "items": .object([
                        "type": .string("object"),
                        "additionalProperties": .bool(false),
                        "required": .array([.string("family"), .string("id")]),
                        "properties": .object([
                            "family": .object([
                                "type": .string("string"),
                                "enum": .array([
                                    .string("order"),
                                    .string("product"),
                                    .string("product_variation"),
                                    .string("customer"),
                                    .string("analytics_stats")
                                ])
                            ]),
                            "id": .object([
                                "type": .string("string"),
                                "description": .string("Entity id, or " +
                                    "analytics_<revenue|orders>:after:<YYYY-MM-DD>:before:<YYYY-MM-DD>:" +
                                    "interval:<hour|day|week|month|year>:currency:<ISO|none> for analytics_stats.")
                            ]),
                            "parent_id": .object([
                                "type": .string("string"),
                                "pattern": .string("^[1-9][0-9]*$")
                            ])
                        ])
                    ])
                ])
            ])
        ]),
        safetyLevel: .safe
    )

    private static func projection(of resolutions: [Resolution], requested: Int) -> ToolResult {
        var resolvedRefs: [AnyCodableJSON] = []
        var missingRefs: [AnyCodableJSON] = []
        var rejectedRefs: [AnyCodableJSON] = []
        var cards: [RenderedCardPayload] = []

        for resolution in resolutions {
            switch resolution {
            case .resolved(let family, let id, let entity):
                let element = encodeEntity(entity)
                resolvedRefs.append(.object([
                    "family": .string(family.rawValue),
                    "id": .string(id),
                    "summary": summary(family: family, element: element)
                ]))
                cards.append(RenderedCardPayload(family: family, id: id, element: element))
            case .rejected(let family, let id, let reason):
                var entry: [String: AnyCodableJSON] = [
                    "reason": .string(reason.rawValue)
                ]
                if let family { entry["family"] = .string(family.rawValue) }
                if let id { entry["id"] = .string(id) }
                switch reason.bucket {
                case .missing:
                    missingRefs.append(.object(entry))
                case .rejected:
                    rejectedRefs.append(.object(entry))
                }
            }
        }

        let validated = resolvedRefs.count + missingRefs.count
        let structured: AnyCodableJSON = .object([
            "requested": .int(Int64(requested)),
            "validated": .int(Int64(validated)),
            "rendered": .int(Int64(resolvedRefs.count)),
            "resolved_refs": .array(resolvedRefs),
            "missing_refs": .array(missingRefs),
            "rejected_refs": .array(rejectedRefs)
        ])
        let uiStructured: UIStructured? = cards.isEmpty ? nil : UIStructured(cards: cards)
        return .success(.init(toolName: name,
                              structured: structured,
                              uiStructured: uiStructured))
    }

    private static func encodeEntity(_ entity: CardEntity) -> AnyCodableJSON {
        guard let json = CardEntityPayloadFactory.json(from: entity) else {
            DDLogError("ShowCardsTool failed to encode card entity")
            return .object([:])
        }
        return json
    }

    private static func summary(family: CardFamily, element: AnyCodableJSON) -> AnyCodableJSON {
        let keys: [String]
        switch family {
        case .analyticsStats:
            return element
        case .order:
            keys = ["id", "number", "status", "total", "currency", "date_created", "customer_name"]
        case .product:
            keys = ["id", "name", "sku", "price", "stock_status"]
        case .productVariation:
            keys = ["id", "name", "sku", "price", "stock_status", "parent_id"]
        case .customer:
            keys = ["id", "first_name", "last_name", "email", "orders_count"]
        }

        guard case .object(let dict) = element else { return .object([:]) }
        var projected: [String: AnyCodableJSON] = [:]
        for key in keys {
            if let value = dict[key] {
                projected[key] = value
            }
        }
        return .object(projected)
    }
}
