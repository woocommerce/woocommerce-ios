import Foundation

public struct ConfirmationSnapshot: Equatable, Sendable {
    public let currentValues: [String: ConfirmationPreviewText]
    /// Optional human label for the targeted entity (product name, customer name).
    /// When set, the preview builder uses it to enrich the summary line.
    public let displayName: String?

    public init(currentValues: [String: ConfirmationPreviewText],
                displayName: String? = nil) {
        self.currentValues = currentValues
        self.displayName = displayName
    }
}

public protocol ConfirmationSnapshotResolving: Sendable {
    func resolve(toolName: String, arguments: String) async -> ConfirmationSnapshot?
}
