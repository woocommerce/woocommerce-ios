import Foundation

public struct ConfirmationSnapshot: Equatable, Sendable {
    public let currentValues: [String: ConfirmationPreviewText]
    /// Optional human label for the targeted entity (product name, customer name).
    /// When set, the preview builder uses it to enrich the summary line.
    public let displayName: String?
    /// Per-entity labels for bulk previews: one row per affected id with its
    /// resolved display name when the resolver can fetch it.
    public let bulkEntries: [ConfirmationBulkEntry]
    /// Variation counts keyed by variable parent id. Populated when a products_update
    /// entry sets `target.scope = "all_variations"` so the preview can show the real
    /// fanout scope ("12 variations") instead of an opaque parent id.
    public let parentVariationCounts: [Int: Int]
    /// When set, the snapshot resolver has determined the call cannot proceed (e.g.
    /// targets reference missing entities). Safety + orchestrator short-circuit: no
    /// confirmation card, no executor dispatch; the model sees a typed tool failure.
    public let refusalReason: String?

    public init(currentValues: [String: ConfirmationPreviewText],
                displayName: String? = nil,
                bulkEntries: [ConfirmationBulkEntry] = [],
                parentVariationCounts: [Int: Int] = [:],
                refusalReason: String? = nil) {
        self.currentValues = currentValues
        self.displayName = displayName
        self.bulkEntries = bulkEntries
        self.parentVariationCounts = parentVariationCounts
        self.refusalReason = refusalReason
    }
}

public struct ConfirmationBulkEntry: Equatable, Sendable {
    public let id: Int
    public let displayName: String?
    /// Nested rows (typically the resolved variations under a variable parent
    /// targeted with `scope=all_variations`) so the card can list what the
    /// fanout actually mutates instead of just the parent id.
    public let subEntries: [ConfirmationBulkEntry]

    public init(id: Int,
                displayName: String? = nil,
                subEntries: [ConfirmationBulkEntry] = []) {
        self.id = id
        self.displayName = displayName
        self.subEntries = subEntries
    }
}

public protocol ConfirmationSnapshotResolving: Sendable {
    func resolve(toolName: String, arguments: String) async -> ConfirmationSnapshot?
}
