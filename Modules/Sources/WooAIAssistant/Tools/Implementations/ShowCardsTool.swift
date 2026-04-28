import Foundation

public enum ShowCardsTool {

    public static let name = "show_cards"

    public static func make(registry: CardFamilyRegistry = .defaultRegistry()) -> RESTTool {
        RESTTool(definition: definition, executor: executor(registry: registry))
    }

    private static let definition = AITool(
        name: name,
        description: """
        Render rich cards for specific entities the user should see. Call \
        this whenever you would otherwise mention an order/product/customer \
        ID in prose. Up to 10 references per call. Prefer 1-5 for list-style \
        answers; summarize the rest in prose.
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
                                "enum": .array([.string("order"), .string("product"), .string("customer")])
                            ]),
                            "id": .object([
                                "type": .string("string"),
                                "pattern": .string("^[1-9][0-9]*$")
                            ])
                        ])
                    ])
                ])
            ])
        ])
    )

    private static func executor(registry: CardFamilyRegistry) -> @Sendable (String, WCRESTClient) async -> ToolResult {
        return { arguments, client in
            let request: ShowCardsRequest
            switch RESTToolDispatch.decodeArguments(ShowCardsRequest.self, from: arguments, toolName: name) {
            case .success(let value): request = value
            case .failure(let failed): return .failed(failed)
            }
            let resolver = CardReferenceResolver(registry: registry, client: client)
            let resolutions = await resolver.resolve(request.references)
            return projection(of: resolutions, requested: request.references.count)
        }
    }

    private static func projection(of resolutions: [Resolution], requested: Int) -> ToolResult {
        var resolvedRefs: [AnyCodableJSON] = []
        var missingRefs: [AnyCodableJSON] = []
        var rejectedRefs: [AnyCodableJSON] = []
        var cards: [RenderedCardPayload] = []

        for resolution in resolutions {
            switch resolution {
            case .resolved(let family, let id, let summary, let rendered):
                resolvedRefs.append(.object([
                    "family": .string(family.rawValue),
                    "id": .string(id),
                    "summary": summary
                ]))
                cards.append(rendered)
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
                              toolCallID: "",
                              structured: structured,
                              uiStructured: uiStructured))
    }
}
