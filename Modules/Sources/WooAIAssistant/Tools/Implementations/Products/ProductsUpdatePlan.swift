import Foundation

struct PlannedWrite: Sendable {
    let entryID: Int
    let targetID: Int
    let expandedParent: Int?
    let patch: [String: AnyCodableJSON]
}

struct EntryPlan: Sendable {
    let entryID: Int
    let expandedParent: Int?
    let preDispatchFailures: [(Int, String)]
    let writes: [PlannedWrite]

    init(entryID: Int,
         expandedParent: Int? = nil,
         preDispatchFailures: [(Int, String)] = [],
         writes: [PlannedWrite] = []) {
        self.entryID = entryID
        self.expandedParent = expandedParent
        self.preDispatchFailures = preDispatchFailures
        self.writes = writes
    }
}

enum BatchDestination: Hashable, Sendable {
    case topLevel
    case variations(parentID: Int)

    var path: String {
        switch self {
        case .topLevel:
            return "wc/v3/products/batch"
        case .variations(let parentID):
            return "wc/v3/products/\(parentID)/variations/batch"
        }
    }
}

struct BatchCall: Sendable {
    let destination: BatchDestination
    let writes: [PlannedWrite]
}

struct BatchOutcome: Sendable {
    let batch: BatchCall
    let successes: [Int]
    let failures: [(Int, String)]
    let outcomeUnknownStatuses: [Int]
}

struct RunReceipt: Sendable {
    let payload: AnyCodableJSON
    /// Non-empty when any batch response was transport-uncertain; surfaces as `.outcomeUnknown`.
    let outcomeUnknownStatuses: [Int]
}
