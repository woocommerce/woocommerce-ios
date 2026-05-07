import Foundation

public struct ConfirmationSnapshot: Equatable, Sendable {
    public let currentValues: [String: ConfirmationPreviewText]

    public init(currentValues: [String: ConfirmationPreviewText]) {
        self.currentValues = currentValues
    }
}

public protocol ConfirmationSnapshotResolving: Sendable {
    func resolve(toolName: String, arguments: String) async -> ConfirmationSnapshot?
}
