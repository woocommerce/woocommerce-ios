import Foundation

public struct ShowCardsCounts: Equatable, Sendable {
    public let requestedCount: Int
    public let renderedCount: Int
    public let missingCount: Int
    public let rejectedCount: Int

    public init(requestedCount: Int,
                renderedCount: Int,
                missingCount: Int,
                rejectedCount: Int) {
        self.requestedCount = requestedCount
        self.renderedCount = renderedCount
        self.missingCount = missingCount
        self.rejectedCount = rejectedCount
    }
}

enum ShowCardsTelemetryReducer {

    static func reduce(_ structured: AnyCodableJSON) -> ShowCardsCounts? {
        guard case .object(let dict) = structured else { return nil }
        guard let requested = intValue(dict["requested"]),
              let rendered = intValue(dict["rendered"]) else {
            return nil
        }
        let missing = arrayCount(dict["missing_refs"]) ?? 0
        let rejected = arrayCount(dict["rejected_refs"]) ?? 0
        return ShowCardsCounts(requestedCount: requested,
                               renderedCount: rendered,
                               missingCount: missing,
                               rejectedCount: rejected)
    }

    private static func intValue(_ value: AnyCodableJSON?) -> Int? {
        guard let value else { return nil }
        switch value {
        case .int(let int): return Int(int)
        case .double(let double): return Int(double)
        default: return nil
        }
    }

    private static func arrayCount(_ value: AnyCodableJSON?) -> Int? {
        guard let value, case .array(let entries) = value else { return nil }
        return entries.count
    }
}
