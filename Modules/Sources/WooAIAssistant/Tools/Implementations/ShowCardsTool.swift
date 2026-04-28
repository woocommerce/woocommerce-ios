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
                                "type": .string("integer"),
                                "minimum": .int(1)
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
            let result = await resolver.resolve(request.references)
            return projection(of: result, requested: request.references.count)
        }
    }

    private static func projection(of result: ShowCardsResult, requested: Int) -> ToolResult {
        var resolvedCount: Int64 = 0
        var rejectedCount: Int64 = 0
        var entries: [AnyCodableJSON] = []
        var cards: [RenderedCardPayload] = []

        for resolution in result.resolutions {
            switch resolution {
            case .resolved(let family, let id, let summary, let rendered):
                resolvedCount += 1
                entries.append(.object([
                    "family": .string(family.rawValue),
                    "id": .int(id),
                    "status": .string("resolved"),
                    "summary": summary
                ]))
                cards.append(rendered)
            case .rejected(let family, let id, let reason):
                rejectedCount += 1
                var entry: [String: AnyCodableJSON] = [
                    "status": .string("rejected"),
                    "reason": .string(reason.rawValue)
                ]
                if let family { entry["family"] = .string(family.rawValue) }
                if let id { entry["id"] = .int(id) }
                entries.append(.object(entry))
            }
        }

        let structured: AnyCodableJSON = .object([
            "requested": .int(Int64(requested)),
            "resolved": .int(resolvedCount),
            "rejected": .int(rejectedCount),
            "resolutions": .array(entries)
        ])
        let uiStructured: UIStructured? = cards.isEmpty ? nil : UIStructured(cards: cards)
        return .success(.init(toolName: name,
                              toolCallID: "",
                              structured: structured,
                              uiStructured: uiStructured))
    }
}
