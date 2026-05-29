public struct DefaultSafetyPolicy: SafetyPolicy {

    private let snapshotResolver: ConfirmationSnapshotResolving?
    private let previewBuilder: ConfirmationPreviewBuilding

    public init(snapshotResolver: ConfirmationSnapshotResolving? = nil,
                previewBuilder: ConfirmationPreviewBuilding = DefaultConfirmationPreviewBuilder()) {
        self.snapshotResolver = snapshotResolver
        self.previewBuilder = previewBuilder
    }

    public func decision(for name: String, arguments: String, tool: AITool) async -> SafetyDecision {
        switch tool.safetyLevel {
        case .safe:
            return .execute
        case .unsafe:
            let snapshot = await snapshotResolver?.resolve(toolName: name, arguments: arguments)
            let preview = previewBuilder.build(toolName: name,
                                               arguments: arguments,
                                               snapshot: snapshot)
                ?? ConfirmationPreview(summary: .raw(name))
            return .requireConfirmation(preview: preview)
        }
    }
}
