import Foundation

enum MessageSegmentGrouping {

    enum Group: Equatable {
        case solo(MessageSegment)
        case cardRun(family: CardRunFamily, segments: [MessageSegment])

        // Anchored to the first segment id so ForEach diffing stays stable as cards stream in.
        var identifier: UUID {
            switch self {
            case .solo(let segment):
                return segment.id
            case .cardRun(_, let segments):
                return segments.first?.id ?? UUID()
            }
        }
    }

    enum CardRunFamily: Equatable {
        case order
        case product
        case productVariation
        case customer
    }

    static func group(_ segments: [MessageSegment]) -> [Group] {
        var groups: [Group] = []
        var pendingFamily: CardRunFamily?
        var pending: [MessageSegment] = []

        func flush() {
            guard let family = pendingFamily, !pending.isEmpty else { return }
            if pending.count == 1 {
                groups.append(.solo(pending[0]))
            } else {
                groups.append(.cardRun(family: family, segments: pending))
            }
            pendingFamily = nil
            pending = []
        }

        for segment in segments {
            if case .cardRender(_, _, let toolName, _) = segment,
               let family = runFamily(forToolName: toolName) {
                if pendingFamily == family {
                    pending.append(segment)
                } else {
                    flush()
                    pendingFamily = family
                    pending = [segment]
                }
            } else {
                flush()
                groups.append(.solo(segment))
            }
        }
        flush()
        return groups
    }

    static func runFamily(forToolName toolName: String) -> CardRunFamily? {
        switch TypedCardDispatcher.route(for: toolName) {
        case .order:
            return .order
        case .product:
            return .product
        case .productVariation:
            return .productVariation
        case .customer:
            return .customer
        case .analyticsStats, .unknown:
            return nil
        }
    }
}
