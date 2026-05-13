import Foundation

public struct ConfirmationSnapshot: Equatable, Sendable {
    public let currentValues: [String: ConfirmationPreviewText]
    /// Optional human label for the targeted entity (product name, customer name).
    /// When set, the preview builder uses it to enrich the summary line.
    public let displayName: String?
    /// Per-entity labels for bulk previews: one row per affected id with its
    /// resolved display name when the resolver can fetch it.
    public let bulkEntries: [ConfirmationBulkEntry]

    public init(currentValues: [String: ConfirmationPreviewText],
                displayName: String? = nil,
                bulkEntries: [ConfirmationBulkEntry] = []) {
        self.currentValues = currentValues
        self.displayName = displayName
        self.bulkEntries = bulkEntries
    }
}

public struct ConfirmationBulkEntry: Equatable, Sendable {
    public let id: Int
    public let displayName: String?

    public init(id: Int, displayName: String? = nil) {
        self.id = id
        self.displayName = displayName
    }
}

public protocol ConfirmationSnapshotResolving: Sendable {
    func resolve(toolName: String, arguments: String) async -> ConfirmationSnapshot?
}
