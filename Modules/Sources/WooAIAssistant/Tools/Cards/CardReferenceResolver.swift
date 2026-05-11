import Foundation

struct CardReferenceResolver: Sendable {
    static let maxReferencesPerCall = 10

    private let client: WCRESTClient

    init(client: WCRESTClient) {
        self.client = client
    }

    func resolve(_ references: [CardReference]) async -> [Resolution] {
        let bounded = Array(references.prefix(Self.maxReferencesPerCall))
        var resolutions: [Resolution?] = Array(repeating: nil, count: bounded.count)
        var seen: Set<SeenKey> = []
        var entitySlotsByFamily: [CardFamilyID: [EntityFetchSlot]] = [:]
        var analyticsSlots: [AnalyticsFetchSlot] = []

        for (index, reference) in bounded.enumerated() {
            let key = SeenKey(family: reference.family, id: reference.id)
            if seen.contains(key) {
                resolutions[index] = .rejected(family: reference.family, id: reference.id, reason: .duplicate)
                continue
            }
            switch reference.family {
            case .analyticsStats:
                guard let spec = AnalyticsCardSpec.decode(reference.id) else {
                    resolutions[index] = .rejected(family: reference.family, id: reference.id, reason: .malformed)
                    continue
                }
                seen.insert(key)
                analyticsSlots.append(AnalyticsFetchSlot(slot: index, id: reference.id, spec: spec))
            case .order, .product, .productVariation, .customer:
                guard let parsed = Int64(reference.id), parsed > 0 else {
                    resolutions[index] = .rejected(family: reference.family, id: reference.id, reason: .malformed)
                    continue
                }
                var parentParsed: Int64?
                if reference.family == .productVariation {
                    guard let parentRaw = reference.parentID,
                          let parsedParent = Int64(parentRaw),
                          parsedParent > 0 else {
                        resolutions[index] = .rejected(family: reference.family, id: reference.id, reason: .malformed)
                        continue
                    }
                    parentParsed = parsedParent
                }
                seen.insert(key)
                entitySlotsByFamily[reference.family, default: []].append(
                    EntityFetchSlot(slot: index, id: reference.id, parsed: parsed, parentParsed: parentParsed)
                )
            }
        }

        let analyticsFetcher = AnalyticsCardFetch(client: client)

        await withTaskGroup(of: ResolverWork.self) { group in
            for (familyID, slots) in entitySlotsByFamily {
                let family = CardFamily.forID(familyID)
                group.addTask {
                    let outcomes: [Int64: CardFetchOutcome]
                    switch family.pathStrategy {
                    case .batchedList:
                        outcomes = await family.fetch(ids: slots.map { $0.parsed }, client: client)
                    case .nestedByParent:
                        let nestedRefs: [(id: Int64, parentID: Int64)] = slots.compactMap { slot in
                            guard let parent = slot.parentParsed else { return nil }
                            return (id: slot.parsed, parentID: parent)
                        }
                        outcomes = await family.fetchNested(refs: nestedRefs, client: client)
                    }
                    return .entities(family: familyID, outcomes: outcomes)
                }
            }
            for slot in analyticsSlots {
                group.addTask {
                    let outcome = await analyticsFetcher.fetch(slot.spec)
                    return .analytics(slot: slot, outcome: outcome)
                }
            }
            for await work in group {
                switch work {
                case .entities(let familyID, let outcomes):
                    guard let slots = entitySlotsByFamily[familyID] else { continue }
                    let family = CardFamily.forID(familyID)
                    for entry in slots {
                        let outcome = outcomes[entry.parsed] ?? .rejected(.notFound)
                        resolutions[entry.slot] = resolution(family: familyID,
                                                             id: entry.id,
                                                             outcome: outcome,
                                                             summarize: family.summarize)
                    }
                case .analytics(let slot, let outcome):
                    // Project the full summary down to model-visible keys; the rendered
                    // card payload keeps the per-bucket data the chart needs.
                    resolutions[slot.slot] = resolution(family: .analyticsStats,
                                                        id: slot.id,
                                                        outcome: outcome,
                                                        summarize: { entity in
                                                            RESTResponseParsing.project(entity,
                                                                                        keys: AnalyticsStatsSummary.modelVisibleKeys)
                                                        })
                }
            }
        }

        let assigned = resolutions.compactMap { $0 }
        precondition(assigned.count == bounded.count, "every bounded slot must be assigned")
        var final = assigned

        // Truncate-and-warn on overflow rather than rejecting the whole call:
        // the merchant still gets the first 10 cards, and the model sees a
        // count mismatch big enough to learn from.
        if references.count > Self.maxReferencesPerCall {
            let overflow = references.count - Self.maxReferencesPerCall
            final.append(contentsOf: Array(
                repeating: Resolution.rejected(family: nil, id: nil, reason: .overLimit),
                count: overflow
            ))
        }
        return final
    }

    private func resolution(family: CardFamilyID,
                            id: String,
                            outcome: CardFetchOutcome,
                            summarize: (AnyCodableJSON) -> AnyCodableJSON) -> Resolution {
        switch outcome {
        case .found(let entity):
            let enriched = Self.enrich(entity, family: family)
            let summary = summarize(enriched)
            let rendered = RenderedCardPayload(family: family, id: id, element: enriched)
            return .resolved(family: family, id: id, summary: summary, rendered: rendered)
        case .rejected(let reason):
            return .rejected(family: family, id: id, reason: reason)
        }
    }

    // WC's product entity exposes the variation list as `variations: [Long]` but never a count.
    // Callers (model summary + UI card row) read `variations_count`; synthesize it once here so
    // both downstream paths see the same field without re-deriving it.
    static func enrich(_ entity: AnyCodableJSON, family: CardFamilyID) -> AnyCodableJSON {
        guard family == .product, case .object(var dict) = entity, dict["variations_count"] == nil else {
            return entity
        }
        if case .array(let variations) = dict["variations"] ?? .null {
            dict["variations_count"] = .int(Int64(variations.count))
        }
        return .object(dict)
    }

    private struct SeenKey: Hashable {
        let family: CardFamilyID
        let id: String
    }

    private struct EntityFetchSlot {
        let slot: Int
        let id: String
        let parsed: Int64
        let parentParsed: Int64?
    }

    private struct AnalyticsFetchSlot: Sendable {
        let slot: Int
        let id: String
        let spec: AnalyticsCardSpec
    }

    private enum ResolverWork: Sendable {
        case entities(family: CardFamilyID, outcomes: [Int64: CardFetchOutcome])
        case analytics(slot: AnalyticsFetchSlot, outcome: CardFetchOutcome)
    }
}
