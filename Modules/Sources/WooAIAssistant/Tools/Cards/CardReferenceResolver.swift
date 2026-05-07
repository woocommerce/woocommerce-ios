import Foundation

struct CardReferenceResolver: Sendable {
    static let maxReferencesPerCall = 10

    private let dataSources: [CardFamily: any CardEntityDataSource]

    init(dataSources: [CardFamily: any CardEntityDataSource]) {
        self.dataSources = dataSources
    }

    func resolve(_ references: [CardReference], analyticsClient: WCRESTClient? = nil) async -> [Resolution] {
        let bounded = Array(references.prefix(Self.maxReferencesPerCall))
        var resolutions: [Resolution?] = Array(repeating: nil, count: bounded.count)
        var seen: Set<SeenKey> = []
        var slotsByFamily: [CardFamily: [Slot]] = [:]
        var analyticsSlots: [AnalyticsSlot] = []

        for (index, reference) in bounded.enumerated() {
            let key = SeenKey(family: reference.family, id: reference.id)
            if seen.contains(key) {
                resolutions[index] = .rejected(family: reference.family, id: reference.id, reason: .duplicate)
                continue
            }

            if reference.family == .analyticsStats {
                guard let spec = AnalyticsCardSpec.decode(reference.id) else {
                    resolutions[index] = .rejected(family: reference.family, id: reference.id, reason: .malformed)
                    continue
                }
                seen.insert(key)
                analyticsSlots.append(AnalyticsSlot(index: index, id: reference.id, spec: spec))
                continue
            }

            guard let parsed = Int64(reference.id), parsed > 0 else {
                resolutions[index] = .rejected(family: reference.family, id: reference.id, reason: .malformed)
                continue
            }
            var parentParsed: Int64 = 0
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
            let ref = CardRef(family: reference.family, id: parsed, parentID: parentParsed)
            slotsByFamily[reference.family, default: []].append(Slot(index: index, id: reference.id, ref: ref))
        }

        await withTaskGroup(of: ResolverWork.self) { group in
            for (family, slots) in slotsByFamily {
                guard let dataSource = dataSources[family] else {
                    for slot in slots {
                        resolutions[slot.index] = .rejected(family: family, id: slot.id, reason: .internalError)
                    }
                    continue
                }
                let refs = slots.map { $0.ref }
                group.addTask {
                    let outcomes = await dataSource.fetch(refs: refs)
                    return .entities(family: family, outcomes: outcomes)
                }
            }
            if let analyticsClient {
                let analyticsFetcher = AnalyticsCardFetch(client: analyticsClient)
                for slot in analyticsSlots {
                    group.addTask {
                        let outcome = await analyticsFetcher.fetch(slot.spec)
                        return .analytics(slot: slot, outcome: outcome)
                    }
                }
            } else {
                for slot in analyticsSlots {
                    resolutions[slot.index] = .rejected(family: .analyticsStats, id: slot.id, reason: .internalError)
                }
            }

            for await work in group {
                switch work {
                case .entities(let family, let outcomes):
                    guard let slots = slotsByFamily[family] else { continue }
                    for slot in slots {
                        let outcome = outcomes[slot.ref] ?? .rejected(.notFound)
                        resolutions[slot.index] = resolution(family: family, id: slot.id, outcome: outcome)
                    }
                case .analytics(let slot, let outcome):
                    resolutions[slot.index] = resolution(family: .analyticsStats, id: slot.id, outcome: outcome)
                }
            }
        }

        let assigned = resolutions.compactMap { $0 }
        precondition(assigned.count == bounded.count, "every bounded slot must be assigned")
        var final = assigned

        if references.count > Self.maxReferencesPerCall {
            let overflow = references.count - Self.maxReferencesPerCall
            final.append(contentsOf: Array(
                repeating: Resolution.rejected(family: nil, id: nil, reason: .overLimit),
                count: overflow
            ))
        }
        return final
    }

    private func resolution(family: CardFamily, id: String, outcome: CardEntityOutcome) -> Resolution {
        switch outcome {
        case .found(let entity):
            return .resolved(family: family, id: id, entity: entity)
        case .rejected(let reason):
            return .rejected(family: family, id: id, reason: reason)
        }
    }

    private struct SeenKey: Hashable {
        let family: CardFamily
        let id: String
    }

    private struct Slot: Sendable {
        let index: Int
        let id: String
        let ref: CardRef
    }

    private struct AnalyticsSlot: Sendable {
        let index: Int
        let id: String
        let spec: AnalyticsCardSpec
    }

    private enum ResolverWork: Sendable {
        case entities(family: CardFamily, outcomes: [CardRef: CardEntityOutcome])
        case analytics(slot: AnalyticsSlot, outcome: CardEntityOutcome)
    }
}
